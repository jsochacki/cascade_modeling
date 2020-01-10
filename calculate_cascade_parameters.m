function [results] = calculate_cascade_parameters(cascade, receiver)
%%%
% Variable (units)
% Pout 1dB or SAT (dBm)
% Gain (dB)
% Noise Figure (dB)
% OIP3 (dB)
% Pout (dBm)
% Headroom (dB)
% Cumulative Gain (dB)
% Cumulative OIP3 (dBm)
% Cumulative Noise Figure (dB)
% Stage Noise (dBm/Hz)
% Receiver Noise Power (dBm)
% In Band Noise Power (dBm)
% Receiver SNR (dB)
% Channel SNR (dB)
% Processed SNR (dB)

destruction_compression = 7;

results.converter_processing_gain = 10*log10(receiver.sample_rate / receiver.channel_bandwidth);
results.receiver_input_noise_power = 10*log10((1.38064852e-23)*((273.15 + receiver.antenna_noise_temperature) / 0.001));

if strcmp(lower(cascade{max(size(cascade))}.name),'converter')
   cin = max(size(cascade));

   power_out_dBm = cascade{cin}.pout;
   
   if ~isnan(cascade{cin}.IMD3_power_dBc) && ~isnan(cascade{cin}.IMD3_power_dBFS)
      cascade{cin}.OIP3 = power_out_dBm + cascade{cin}.IMD3_power_dBFS - (cascade{cin}.IMD3_power_dBc / 2);
   end
   
   if ~isnan(cascade{cin}.SNR_dB) && ~isnan(cascade{cin}.SNR_power_dBFS) && ~isnan(cascade{cin}.SNR_sample_rate_Hz)
      NA = power_out_dBm + cascade{cin}.SNR_power_dBFS - cascade{cin}.SNR_dB - 10*log10(cascade{cin}.SNR_sample_rate_Hz / 2);
      cascade{cin}.NF = NA - 10*log10((1.38064852e-23)*((273.15 + receiver.temperature) / 0.001));
   else
      NA = power_out_dBm - (20*log10(power(2, cascade{cin}.ENOB)) + 1.76) - 10*log10(receiver.sample_rate / 2);
      cascade{cin}.NF = NA - 10*log10((1.38064852e-23)*((273.15 + receiver.temperature) / 0.001));
   end
   
   cascade{cin}.gain = 0;

else
   power_out_dBm = receiver.pout;
end

power_in_dBm = receiver.pin;

%I don't apply PAPR effects to amplifier gain as the amplifiers will have
%an average operation point of their average power but it can be applied to
%distortion or not depending on whether or not you want a worst case number
for n = 1:1:max(size(cascade))
   cascade{n}.destruction_compression = destruction_compression;
   if (cascade{n}.pout ~= Inf) && (~strcmp(lower(cascade{n}.name),'converter'))
      cascade{n}.IP1dB = cascade{n}.pout - (cascade{n}.gain - 1);
      cascade{n}.IIP3 = cascade{n}.OIP3 - cascade{n}.gain;
      a1 = power(10, cascade{n}.gain / 20);
      a3 = -((4/3)*abs(a1)) / power(10, (cascade{n}.IP1dB - 20*log10(sqrt(abs(power(10, -1 / 20) - 1)))) / 10);
      cascade{n}.apparent_signal_gain = @(signal_in_dBm, secondary_signal_in_dBm) ...
                                           20*log10(a1*(1 ...
                                                        + ((3/4)*(a3/a1)*abs(power(10, signal_in_dBm / 20)).^2) ...
                                                        + ((3/2)*(a3/a1)*abs(power(10, secondary_signal_in_dBm / 20)).^2) ...
                                                        + ((3/2)*(a3/a1)*abs(power(10, secondary_signal_in_dBm / 20) ...
                                                                           * power(10, signal_in_dBm / 20)))));
      cascade{n}.IM3_dBc = @(signal_in_dBm) - 2*(cascade{n}.IIP3 - signal_in_dBm);
      cascade{n}.IM3_dBm = @(signal_in_dBm) cascade{n}.OIP3 - 3*(cascade{n}.IIP3 - signal_in_dBm);
      %More accurate if CDF shows PAPR has more than just one or two peaks
%       cascade{n}.IM3_dBc = @(signal_in_dBm) - 2*(cascade{n}.IIP3 - (signal_in_dBm + receiver.waveform_PAPR));
%       cascade{n}.IM3_dBm = @(signal_in_dBm) cascade{n}.OIP3 - 3*(cascade{n}.IIP3 - (signal_in_dBm + receiver.waveform_PAPR));
      %So we can adjust and recude PAPR to have smaller effect assuming that
      %the waveform has more and >75% of it at average power (50% is 3dB,
      %75% is 6dB and so on)
      cascade{n}.protected_gain = @protected_gain;
      cascade{n}.compression = @(signal_in_dBm, secondary_signal_in_dBm) cascade{n}.gain - cascade{n}.protected_gain(cascade{n}, signal_in_dBm, secondary_signal_in_dBm);
   elseif  (cascade{n}.pout ~= Inf) && (strcmp(lower(cascade{n}.name),'converter'))
      cascade{n}.IP1dB = cascade{n}.pout + 1;
      cascade{n}.IIP3 = cascade{n}.OIP3;
      %With full Clipping Modeled
      %cascade{n}.IM3_dBc = @(signal_in_dBm) ((-2*(cascade{n}.IIP3 - signal_in_dBm).*(signal_in_dBm <= cascade{n}.IP1dB)) + (-6*((cascade{n}.IP1dB + ((cascade{n}.IIP3 - cascade{n}.IP1dB)/4)) - signal_in_dBm).*(signal_in_dBm > cascade{n}.IP1dB)));
      %With some Clipping Modeled
      %cascade{n}.IM3_dBc = @(signal_in_dBm) ((-2*(cascade{n}.IIP3 - signal_in_dBm).*(signal_in_dBm <= cascade{n}.IP1dB)) + (-4*((cascade{n}.IP1dB + ((cascade{n}.IIP3 - cascade{n}.IP1dB)/2)) - signal_in_dBm).*(signal_in_dBm > cascade{n}.IP1dB)));
      %No Clipping Modeled
      cascade{n}.IM3_dBc = @(signal_in_dBm) - 2*(cascade{n}.IIP3 - signal_in_dBm);
      cascade{n}.IM3_dBm = @(signal_in_dBm) signal_in_dBm + cascade{n}.IM3_dBc(signal_in_dBm);
      %More accurate if CDF shows PAPR has more than just one or two peaks
%       cascade{n}.IM3_dBc = @(signal_in_dBm) ((-2*(cascade{n}.IIP3 - (signal_in_dBm + receiver.waveform_PAPR)).*((signal_in_dBm + receiver.waveform_PAPR) <= cascade{n}.IP1dB)) + (-6*((cascade{n}.IP1dB + ((cascade{n}.IIP3 - cascade{n}.IP1dB)/4)) - (signal_in_dBm + receiver.waveform_PAPR)).*((signal_in_dBm + receiver.waveform_PAPR) > cascade{n}.IP1dB)));
%       cascade{n}.IM3_dBm = @(signal_in_dBm) signal_in_dBm + cascade{n}.IM3_dBc((signal_in_dBm + receiver.waveform_PAPR));
      %So we can adjust and recude PAPR to have smaller effect assuming that
      %the waveform has more and >75% of it at average power (50% is 3dB,
      %75% is 6dB and so on)
      cascade{n}.protected_gain = @converter_gain;
      cascade{n}.compression = @(signal_in_dBm, secondary_signal_in_dBm) cascade{n}.gain - cascade{n}.protected_gain(cascade{n}, signal_in_dBm, secondary_signal_in_dBm);
   end
end


if isnan(receiver.next_largest_signal_dBm)
   receiver.next_largest_signal_dBm = -Inf;
end

direction = 'forward';
if ~isnan(power_out_dBm)
   %Suppose input level from linear calcualtions and then iterate until
   %accurate
   cascade_gain = 0;
   for n = 1:1:(max(size(cascade)))
      cascade_gain = cascade_gain + cascade{n}.gain;
   end
   direction = 'backwards';
end

error_magnitude = 1;
while error_magnitude > 0.01
   if strcmp(direction,'forward')
      results.pout(1) = power_in_dBm;
      error_magnitude = 0;
   else
      results.pout(1) = (power_out_dBm - receiver.waveform_PAPR) - cascade_gain;
   end
   results.secondary_signal_pout(1) = receiver.next_largest_signal_dBm;
   
   results.operational_signal_gain(1) = 0;
   
   results.distortion_power(1) = -Inf;
   
   cnf = 0;
   results.cumulative_gain(1) = results.operational_signal_gain(1);
   results.radio_noise_power(1) = results.receiver_input_noise_power + results.cumulative_gain(1) + cnf + 10*log10(receiver.radio_bandwidth);
   
   temp = [results.pout(1), results.distortion_power(1), results.radio_noise_power(1)];
   results.in_band_power(1) = uncorrelated_power_combine(temp);

   results.gain_compression(1) = 0;
   results.non_linear_noise_power_bandwidth(1) = 3 * receiver.channel_bandwidth;

   results.cumulative_OIP3(1) = 99;

   for n = 2:1:(max(size(cascade)) + 1)
      if isfield(cascade{n - 1}, 'protected_gain')
         receiver_gain = cascade{n - 1}.protected_gain(cascade{n - 1}, results.in_band_power(n - 1), results.secondary_signal_pout(n - 1));
      else
         receiver_gain = cascade{n - 1}.gain;
      end

      results.pout(n) = results.pout(n - 1) + receiver_gain;
      results.secondary_signal_pout(n) = results.secondary_signal_pout(n - 1) + receiver_gain;
      cascade{n - 1}.operational_signal_gain = receiver_gain;
      results.operational_signal_gain(n) = receiver_gain;

      previouse_distortion_power = results.distortion_power(n - 1) + receiver_gain;
      if isfield(cascade{n - 1}, 'IM3_dBm')
         temp = [results.in_band_power(n - 1), results.secondary_signal_pout(n - 1)];
         total_input_power = uncorrelated_power_combine(temp);
         added_distortion_power  = cascade{n - 1}.IM3_dBm(total_input_power);
      else
         added_distortion_power = -Inf;
      end
      temp = [previouse_distortion_power, added_distortion_power];
      results.distortion_power(n) =  uncorrelated_power_combine(temp);

      results.cumulative_gain(n) = results.cumulative_gain(n - 1) + receiver_gain;
      cnf = 10*log10(power(10, cnf / 10) + ((power(10, cascade{n - 1}.NF / 10) - 1) / power(10, results.cumulative_gain(n - 1) / 10)));
      results.radio_noise_power(n) = results.receiver_input_noise_power + results.cumulative_gain(n) + cnf + 10*log10(receiver.radio_bandwidth);

      temp = [results.pout(n), results.distortion_power(n), results.radio_noise_power(n)];
      results.in_band_power(n) = uncorrelated_power_combine(temp);

      results.gain_compression(n) = cascade{n - 1}.gain - receiver_gain;

      if isfield(cascade{n - 1}, 'IM3_dBm')
         array = [results.pout(n - 1), results.distortion_power(n - 1), results.radio_noise_power(n - 1), results.secondary_signal_pout(n - 1)];
         array = array - receiver_gain - 10*log10([3 * receiver.channel_bandwidth, results.non_linear_noise_power_bandwidth(n - 1), receiver.radio_bandwidth, 3 * receiver.channel_bandwidth]);
         array = array(1) - array;
         subset = array(find(array ~= Inf));
         ind = find(ismember(array,min(subset)));
         if isempty(ind)
            %They are all infinite or NaN so 
            error('n = %d , element name is %s, receiver_gain = %d, subset array is [%d %d %d %d]', n, cascade{n - 1}.name, receiver_gain, results.pout(n - 1), results.distortion_power(n - 1), results.radio_noise_power(n - 1), results.secondary_signal_pout(n - 1));
            error('All of the powers are infinite or NaN, you have issues');
         else
            switch ind
               case 1 %largest signal is primary signal so assume nonlinear distortion power is over 3 * channel BW
                  results.non_linear_noise_power_bandwidth(n) = 3 * receiver.channel_bandwidth;
               case 2 %largest signal is distortion power so assume nonlinear distortion power is over radio bandwidth
                  results.non_linear_noise_power_bandwidth(n) = receiver.radio_bandwidth;
               case 3 %largest signal is noise power so assume nonlinear distortion power is over radio bandwidth
                  results.non_linear_noise_power_bandwidth(n) = receiver.radio_bandwidth;
               case 4 %largest signal is secondary signal so assume nonlinear distortion power is over 3 * channel BW
                  results.non_linear_noise_power_bandwidth(n) = 3 * receiver.channel_bandwidth;
               otherwise
                  %Cant get here
                  error('You got to a case you cant get to, investigate');
            end
         end
      else
         results.non_linear_noise_power_bandwidth(n) = results.non_linear_noise_power_bandwidth(n - 1);
      end

      %IM3 = results.distortion_power(n) here but if this ever changes make
      %sure to fix this formula
      results.cumulative_OIP3(n) = results.pout(n) + ((results.pout(n) - results.distortion_power(n)) / 2);
   end

   if strcmp(direction,'backwards')
      %Set signal power only somehow
      %error = (power_out_dBm - receiver.waveform_PAPR) - results.pout(end);
      %Set measured power to level (more realizable)
      error_magnitude = (power_out_dBm - receiver.waveform_PAPR) - results.in_band_power(end);
      cascade_gain = cascade_gain - 0.01;
   end
end

running_total_power = -Inf;

results.headroom(1) = Inf;
results.cumulative_gain_ideal(1) = 0;
results.cumulative_gain_compression(1) = 0;
results.cumulative_OIP3_ideal(1) = 99;
results.cumulative_NF_ideal(1) = 0;
results.cumulative_NF_ideal_real_gain(1) = 0;
results.cumulative_NF(1) = 0;

results.linear_noise_density(1) = results.receiver_input_noise_power;
results.non_linear_noise_density(1) = results.distortion_power(1);

results.stage_noise_density(1) = results.receiver_input_noise_power;
results.in_band_noise_power(1) = results.stage_noise_density(1) + 10*log10(receiver.channel_bandwidth);
results.channel_snr(1) = results.pout(1) - results.in_band_noise_power(1);
results.processed_snr(1) = results.channel_snr(1) + results.converter_processing_gain;

results.nonlinear_degradation_to_SNR(1) = 0;
results.processed_snr_without_nonlinear_degradation(1) = results.processed_snr(1);

results.sensitivity(1) = results.receiver_input_noise_power + 10*log10(receiver.channel_bandwidth);
results.DFDR(1) = results.pout(1) - results.stage_noise_density(1);
results.SFDR(1) = results.pout(1) - max(results.stage_noise_density(1), results.secondary_signal_pout(1));

for n = 1:1:max(size(cascade))
   %Old incorrect method
   %HEADROOM IS THE DIFFERENC IN THE IDEAL LINEAR POWER AT A
   %POINT FROM THE INPUT TO THAT POINT AND THE P1DB OF THE DEVICE AT THAT
   %POINT, SINCE I HAVE A NONLINEAR CASCADE I WILL ALWAYS HAVE A POSITIVE
   %HEADROOM WITH THE CALCULATIONS BELOW AS MY CASCADE COMPRESSES!!!!
   %YOU NEED TO HAVE CASCADE{N}.GAIN + PIN AT EACH STAGE LESS THE
   %CASCADE{N}.POUT
%    temp = [results.in_band_power(n + 1), results.secondary_signal_pout(n + 1)];
%    total_power = uncorrelated_power_combine(temp);
%    results.headroom(n + 1) = cascade{n}.pout - total_power;
   %This is the more correct way to calculate headroom
   %We basically want to take the power based on a linear gain up from the
   %input or represent the power from a linear gain up of some crazy large
   %distortion product created somewhere in the casecade if this takes over
   %and dominates what a linear gain up of the input power would be
   temp = [results.in_band_power(n), results.secondary_signal_pout(n)];
   total_power = max(uncorrelated_power_combine(temp), running_total_power);
   running_total_power = total_power + cascade{n}.gain;
   results.headroom(n + 1) = cascade{n}.pout - running_total_power;

   results.cumulative_gain_ideal(n + 1) = results.cumulative_gain_ideal(n) + cascade{n}.gain;
   results.cumulative_gain_compression(n + 1) = results.cumulative_gain_ideal(n + 1) - results.cumulative_gain(n + 1);
   results.cumulative_OIP3_ideal(n + 1) = 10*log10(1 / ((1 / (power(10, results.cumulative_OIP3_ideal(n) / 10) * power(10, cascade{n}.gain / 10))) + (1 / power(10, cascade{n}.OIP3 / 10))));
   results.cumulative_NF_ideal(n + 1) = 10*log10(power(10, results.cumulative_NF_ideal(n) / 10) + ((power(10, cascade{n}.NF / 10) - 1) / power(10, results.cumulative_gain_ideal(n) / 10)));
   results.cumulative_NF_ideal_real_gain(n + 1) = 10*log10(power(10, results.cumulative_NF_ideal_real_gain(n) / 10) + ((power(10, cascade{n}.NF / 10) - 1) / power(10, results.cumulative_gain(n) / 10)));

   %Same as results.radio_noise_power - 10*log10(receiver.radio_bandwidth)
   results.linear_noise_density(n + 1) = results.receiver_input_noise_power + results.cumulative_gain(n + 1) + results.cumulative_NF_ideal_real_gain(n + 1);
   non_linear_noise_power = results.distortion_power(n + 1);
   results.non_linear_noise_density(n + 1) = non_linear_noise_power - 10*log10(results.non_linear_noise_power_bandwidth(n + 1));

   temp = [results.linear_noise_density(n + 1), results.non_linear_noise_density(n + 1)];
   results.stage_noise_density(n + 1) = uncorrelated_power_combine(temp);
   results.cumulative_NF(n + 1) = results.stage_noise_density(n + 1) - results.cumulative_gain(n + 1) - results.receiver_input_noise_power;
   %Equivalent to above calculation but done with cumulative NF, i have
   %verified they are the same exact result as they should be
   %results.stage_noise_density(n + 1) = results.receiver_input_noise_power + results.cumulative_gain(n + 1) + results.cumulative_NF(n + 1);
   results.in_band_noise_power(n + 1) = results.stage_noise_density(n + 1) + 10*log10(receiver.channel_bandwidth);
   results.channel_snr(n + 1) = results.pout(n + 1) - results.in_band_noise_power(n + 1);
   results.processed_snr(n + 1) = results.channel_snr(n + 1) + results.converter_processing_gain;

   results.nonlinear_degradation_to_SNR(n + 1) = results.stage_noise_density(n + 1) - results.linear_noise_density(n + 1);
   results.processed_snr_without_nonlinear_degradation(n + 1) = results.processed_snr(n + 1) + results.nonlinear_degradation_to_SNR(n + 1);

   %Does not take into account ENB at all, assumes perfect filters and that
   %you have 1 bit / HZ spectral efficiency i.e. 0 dB S/N requirement
   %Textbook but doesn't inclue exactly what Acie wants to capture which is
   %nonlinear degradation etc... and is also inaccurate when modeling as I
   %have done so I fix below
   %results.sensitivity(n + 1) = (results.linear_noise_density(n + 1) - results.cumulative_gain(n + 1)) + 10*log10(receiver.channel_bandwidth);
   results.sensitivity(n + 1) = results.receiver_input_noise_power + 10*log10(receiver.channel_bandwidth) + results.cumulative_NF(n + 1);
   %Again same result as the below calculation so modified NF calculations
   %are correct and sufficinet for Teds code to represent what Acie wants
   %results.sensitivity(n + 1) = (results.stage_noise_density(n + 1) - results.cumulative_gain(n + 1)) + 10*log10(receiver.channel_bandwidth);
   results.DFDR(n + 1) = results.pout(n + 1) - results.stage_noise_density(n + 1);
   results.SFDR(n + 1) = results.pout(n + 1) - max(results.stage_noise_density(n + 1), results.secondary_signal_pout(n + 1));
end

%NOTES
%Calculating Effective NF like i do is technically wrong as the non linear
%distortion should not be represented in NF but rather separately as TOI
%and then have this used to solve for the nonlinear noise so that it can be
%added into the additive noise in the macro calculations like sensitivity
%and SFDR/DFDR since it is correlated distortion to the signal and not random
%additive noise and will not perform the same in trasking loops or STAP
%etc... as pure additive noise would so it will be inaccurate for system
%level calculations aside of what we are trying to do here with the
%tool
%Also, Noise figure is a measure of how system noise power is degraded and
%only that.  It is defined as the 1 + Na/(Ni*G) where Ni is the
%characteristic thermal noise (johnson - nyquist noise which should have
%its R value calculated at Zo and the the P value will actually depend on
%the match to the system impedance as vn^2 = 4*kbTR [v/rt-Hz] vrms = sqrt(4*kbTRB)
%i.e. one must calculate the rms noise voltage and then apply to the actual
%input impedance of the device under test to get the power in i.e. Ni)
%at T = 290K only (room temp).  Anything outside of this deviates from what
%is accurate i.e. change in temperature, etc..
end