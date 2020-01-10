function [cascade] = solve_agc(cascade, receiver, on_off)

%Can set different goal metrics (i.e. minimize distortion power)
%for the AGC but here we will just set
%the goal metric to set the gain such that the Pin is what we have
%specified it to be per the receiver.pin parameter i.e.
%Currently the AGC only sets the attenuators based on the the total power
%at the converter and the specified receiver desired signal in level.
cost_function = @(set_pin, actual_pin) set_pin - actual_pin;

AGC_Resolution = 0.05;

vvas = 0;
total_range = 0;
cascade_locations = [];
for n = 1:1:max(size(cascade))
   if isfield(cascade{n}, 'gain_range')
      %create vva from input structs
      vva{vvas + 1}.gain_range = cascade{n}.gain_range;
      vva{vvas + 1}.initial_attenuation = cascade{n}.initial_attenuation;
      vva{vvas + 1}.base_loss = cascade{n}.base_loss;
      vva{vvas + 1}.base_pin = cascade{n}.base_pin;
      vva{vvas + 1}.base_OIP3 = cascade{n}.base_OIP3;
      vva{vvas + 1}.name = cascade{n}.name;
      %create calculation parameters
      vva{vvas + 1}.current_attenuation = vva{vvas + 1}.initial_attenuation;
      vva{vvas + 1}.gain = @(current_attenuation) -vva{vvas + 1}.base_loss - current_attenuation;
      vva{vvas + 1}.pout = @(current_gain) vva{vvas + 1}.base_pin + current_gain;
      vva{vvas + 1}.NF = @(current_gain) -current_gain;
      vva{vvas + 1}.OIP3 = @(current_pout) current_pout + vva{vvas + 1}.base_OIP3;
      %Cleanup cascade vva structs
      cascade{n}.gain = -cascade{n}.base_loss - cascade{n}.initial_attenuation;
      cascade{n}.pout = cascade{n}.base_pin + cascade{n}.gain;
      cascade{n}.NF = -cascade{n}.gain;
      cascade{n}.OIP3 = cascade{n}.pout + cascade{n}.base_OIP3;
      cascade{n} = rmfield(cascade{n},'gain_range');
      cascade{n} = rmfield(cascade{n},'initial_attenuation');
      cascade{n} = rmfield(cascade{n},'base_loss');
      cascade{n} = rmfield(cascade{n},'base_pin');
      cascade{n} = rmfield(cascade{n},'base_OIP3');
      
      total_range = total_range + vva{vvas + 1}.gain_range;
      vvas = vvas + 1;
      cascade_locations = [cascade_locations n];
   end
end

%If receiver.pin is NaN we have nothing to do for the AGC currently
if (strcmp(lower(on_off),'on') && ~isnan(receiver.pin))
   %Itteratively Solve for the casecade to set VVA values
   %For now VVA values are dialed in in equal parts amongst all VVAs at a
   %AGC_Resolution dB resolution until further functionality is added later

   %So calculate initial value for metric
   temp = calculate_cascade_parameters(cascade, receiver);
   error_magnitude = cost_function(receiver.pin, temp.pout(1));
   
   if error_magnitude < 0
      error_magnitude = 0;
      error(['The AGC cannot increase the power level enough to drive ' ...
            ,'the converter to the desirable level.  Setting AGC ' ...
            ,'to min attenuation and just solving for state of system.']);

      temp_attenuation = 0;
      for n = 1:1:vvas
         cascade{cascade_locations(n)}.gain = vva{n}.gain(temp_attenuation);
         cascade{cascade_locations(n)}.pout = vva{n}.pout(cascade{cascade_locations(n)}.gain);
         cascade{cascade_locations(n)}.NF = vva{n}.NF(cascade{cascade_locations(n)}.gain);
         cascade{cascade_locations(n)}.OIP3 = vva{n}.OIP3(cascade{cascade_locations(n)}.pout);
      end

   elseif error_magnitude > total_range
      error_magnitude = 0;
      error(['The AGC cannot decrease the power level enough to prevent ' ...
            ,'the converter from being overdriven.  Setting AGC ' ...
            ,'to max attenuation and just solving for state of system.']);

      for n = 1:1:vvas
         temp_attenuation = vva{n}.gain_range;
         cascade{cascade_locations(n)}.gain = vva{n}.gain(temp_attenuation);
         cascade{cascade_locations(n)}.pout = vva{n}.pout(cascade{cascade_locations(n)}.gain);
         cascade{cascade_locations(n)}.NF = vva{n}.NF(cascade{cascade_locations(n)}.gain);
         cascade{cascade_locations(n)}.OIP3 = vva{n}.OIP3(cascade{cascade_locations(n)}.pout);
      end

   else
      while abs(error_magnitude) > (2 * AGC_Resolution)
         %Can implement more sophisticated per radio attenuation
         %distribution schemes here
         per_vva_value = floor((error_magnitude / vvas) / AGC_Resolution) * AGC_Resolution;
         carry_over = 0;
         for n = 1:1:vvas
            %Deals with the case where the range of the attenuators is not
            %sufficient, additional attenuation required will be smooshed
            %into later stages, if they cannot accomodate then the loop
            %will itterate and it will eventually accumulate in the front
            %most attenuators but this will itterate slowly as each
            %iteration will only move you towards the required attenuation
            %by 0.5 of what you need to you will itterate to the solition
            %as 0.5^n
            value_with_carry_over = per_vva_value + carry_over;
            if (vva{n}.gain_range - value_with_carry_over) < 0
               assigned_attenuation = vva{n}.gain_range;
               carry_over = value_with_carry_over - assigned_attenuation;
            else
               assigned_attenuation = value_with_carry_over;
               carry_over = 0;
            end
            vva{n}.current_attenuation = vva{n}.current_attenuation + assigned_attenuation; 
            cascade{cascade_locations(n)}.gain = vva{n}.gain(vva{n}.current_attenuation);
            cascade{cascade_locations(n)}.pout = vva{n}.pout(cascade{cascade_locations(n)}.gain);
            cascade{cascade_locations(n)}.NF = vva{n}.NF(cascade{cascade_locations(n)}.gain);
            cascade{cascade_locations(n)}.OIP3 = vva{n}.OIP3(cascade{cascade_locations(n)}.pout);
         end
         
         temp = calculate_cascade_parameters(cascade, receiver);
         error_magnitude = cost_function(receiver.pin, temp.pout(1));
      end
   end

end

end