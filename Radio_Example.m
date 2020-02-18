clear all
clc

%Done at 8GHz only but can be vectorized for all frequencies
% pad1_ammount = 0;
% pad2_ammount = 0;

switch1.pout = 37;
switch1.gain = -0.68;
switch1.NF = -switch1.gain;
switch1.OIP3 = 62;
switch1.name = 'HMC1118';

switch2.pout = 27;
switch2.gain = -0.75;
switch2.NF = -switch2.gain;
switch2.OIP3 = 58;
switch2.name = 'MASW-007107';

amp1.pout = 18;
amp1.gain = 16;
amp1.NF = 3;
amp1.OIP3 = 30;
amp1.name = 'AM1063-1';

filter1.pout = Inf;
filter1.gain = -1.4;
filter1.NF = -filter1.gain;
filter1.OIP3 = 99;
filter1.name = 'Band13_Filter';

limiter1.pout = 15;
limiter1.gain = -0.35;
limiter1.NF = -limiter1.gain;
limiter1.OIP3 = 30;
limiter1.name = 'MPL4701';

amp2.pout = 12;
amp2.gain = 13;
amp2.NF = 3;
amp2.OIP3 = 23;
amp2.name = 'GRF2004';

filter2.pout = Inf;
filter2.gain = -0.77;
filter2.NF = -filter2.gain;
filter2.OIP3 = 99;
filter2.name = 'LFCN-123+';

mixer1.pout = 9;
mixer1.gain = -6.5;
mixer1.NF = 7;
mixer1.OIP3 = 21 + mixer1.gain;
mixer1.name = 'ML1-0603ISM-2';

amp3.pout = 16.5;
amp3.gain = 18.5;
amp3.NF = 2.1;
amp3.OIP3 = 28;
amp3.name = 'CMD186';

vva1.gain_range = 30;
vva1.initial_attenuation = 0;
vva1.base_loss = 3;
vva1.base_pin = 23;
vva1.base_OIP3 = 20;
vva1.name = 'RFSA2113';

filter3.pout = Inf;
filter3.gain = -6;
filter3.NF = -filter3.gain;
filter3.OIP3 = 99;
filter3.name = 'DLI8310';

amp4.pout = 19;
amp4.gain = 15;
amp4.NF = 5.2;
amp4.OIP3 = amp4.pout + 10.6;
amp4.name = 'HMC441LC3B';

filter4.pout = Inf;
filter4.gain = -0.66;
filter4.NF = -filter4.gain;
filter4.OIP3 = 99;
filter4.name = 'LFCW-1142+';

mixer2.pout = 14;
mixer2.gain = -9;
mixer2.NF = 10;
mixer2.OIP3 = 23 + mixer2.gain;
mixer2.name = 'MM1-0424SSM-2';

diplexer1.pout = Inf;
diplexer1.gain = -0.66;
diplexer1.NF = -diplexer1.gain;
diplexer1.OIP3 = 99;
diplexer1.name = 'Custom Diplexer';

switch3.pout = 30;
switch3.gain = -0.9;
switch3.NF = -switch3.gain;
switch3.OIP3 = 43;
switch3.name = 'SKY13267-321';

amp5.pout = 19;
amp5.gain = 16.5;
amp5.NF = 2.5;
amp5.OIP3 = 30;
amp5.name = 'Custom_HBT_Amps';

vva2.gain_range = 30;
vva2.initial_attenuation = 0;
vva2.base_loss = 1;
vva2.base_pin = 24;
vva2.base_OIP3 = 17;
vva2.name = 'RFSA2033';

filter5.pout = Inf;
filter5.gain = -6;
filter5.NF = -filter5.gain;
filter5.OIP3 = 99;
filter5.name = 'Custom Filter';

amp6.pout = 18.5;
amp6.gain = 18.5;
amp6.NF = 3.7;
amp6.OIP3 = 41;
amp6.name = 'SBB2089Z';

switch4.pout = 27;
switch4.gain = -0.35;
switch4.NF = -switch4.gain;
switch4.OIP3 = 49;
switch4.name = 'SKY13323-378LF';

switch5.pout = 31;
switch5.gain = -1.2;
switch5.NF = -switch5.gain;
switch5.OIP3 = 57;
switch5.name = 'PE42540';

amp7.pout = 19;
amp7.gain = 15;
amp7.NF = 4.2;
amp7.OIP3 = 40;
amp7.name = 'SBB1089Z';

%START CONVERTER
%If you don't have a converter you need to specify receiver.pout
v_pkpk = 1.75;
AD9250.pout = 10*log10(power((v_pkpk / 2) / sqrt(2), 2) / (50*0.001)); %FS in dBm
AD9250.name = 'converter';

%Just make these both NaN if you don't want to calculate OIP3 from
%Measurements but you must then specify OIP3 directly below
AD9250.IMD3_power_dBc = -100;
AD9250.IMD3_power_dBFS = -8;

AD9250.OIP3 = NaN;

%Just make these three NaN if you don't want to calculate NF from
%Measurements but you must then specify ENOB directly below
AD9250.SNR_dB = 70;
AD9250.SNR_power_dBFS = -1;
AD9250.SNR_sample_rate_Hz = 250e6;

AD9250.ENOB = NaN; %11
%END CONVERTER

receiver.channel_bandwidth = 100e6;
receiver.sample_rate = AD9250.SNR_sample_rate_Hz;
receiver.radio_bandwidth = 1.86e9; %6000-4140 is the widest preselect filter bandwidth
receiver.antenna_noise_temperature = 16.8;
receiver.temperature = 16.8;
receiver.waveform_PAPR = 8;

%If you don't want to specify or don't have this just put NaN otherwise put
%a number
receiver.next_largest_signal_dBm = NaN;

%If you specify pin then you will solve the cascade based on the input
%power set
%If Pin is not specified then you must specify pout or have a converter at
%the end of the cascade
%Also note that any time you specify a converter at the end of the chain it
%will have an associated pout and will solve from output to input
%If you specify pout then you will solve the cascade based on the output
%power set, PAPR, etc... for the input power
receiver.pout = NaN;
receiver.pin = -30;

cascade = {switch1 switch2 switch2 limiter1 amp1 ...
           switch2 switch2 switch2 filter1 switch2 switch2 limiter1 ...
           amp2 switch2 switch2 filter2 mixer1 switch2 amp3 switch2 ...
           vva1 filter3 switch2 amp4 switch2 filter4 mixer2 ...
           diplexer1 switch3 amp5 switch3 vva2 filter4 switch3 amp6 switch3 filter4 switch4 ...
           switch5 switch5 amp7 AD9250};

Radio.with_Preamp = cascade;

cascade = {switch1 switch2    ...
           switch2 switch2 filter1 switch2 switch2 limiter1 ...
           amp2 switch2 switch2 filter2 mixer1 switch2 amp3 switch2 ...
           vva1 filter3 switch2 amp4 switch2 filter4 mixer2 ...
           diplexer1 switch3 amp5 switch3 vva2 filter4 switch3 amp6 switch3 filter4 switch4 ...
           switch5 switch5 amp7 AD9250};

Radio.without_Preamp = cascade;

%Itterate over power levels
receiver.next_largest_signal_dBm = NaN;
receiver.pin = NaN;

interferer_level_vector = [NaN -80:1:-30];
desired_level_vector = -81:1:-30;
for n = 1:1:length(interferer_level_vector)
   for nn = 1:1:length(desired_level_vector)
      receiver.next_largest_signal_dBm = interferer_level_vector(n);
      receiver.pin = desired_level_vector(nn);

      AGC_STATE = 'off';

      Radio.without_AGC_with_Preamp = solve_agc(Radio.with_Preamp, receiver, AGC_STATE);
      results.without_AGC_with_Preamp = calculate_cascade_parameters(Radio.without_AGC_with_Preamp, receiver);

      Radio.without_AGC_without_Preamp = solve_agc(Radio.without_Preamp, receiver, AGC_STATE);
      results.without_AGC_without_Preamp = calculate_cascade_parameters(Radio.without_AGC_without_Preamp, receiver);

      AGC_STATE = 'on';

      Radio.with_AGC_with_Preamp = solve_agc(Radio.with_Preamp, receiver, AGC_STATE);
      results.with_AGC_with_Preamp = calculate_cascade_parameters(Radio.with_AGC_with_Preamp, receiver);

      Radio.with_AGC_without_Preamp = solve_agc(Radio.without_Preamp, receiver, AGC_STATE);
      results.with_AGC_without_Preamp = calculate_cascade_parameters(Radio.with_AGC_without_Preamp, receiver);
      
      effective_NF.without_AGC_with_Preamp(n, nn) = results.without_AGC_with_Preamp.cumulative_NF(end);
      effective_NF.without_AGC_without_Preamp(n, nn) = results.without_AGC_without_Preamp.cumulative_NF(end);
      effective_NF.with_AGC_with_Preamp(n, nn) = results.with_AGC_with_Preamp.cumulative_NF(end);
      effective_NF.with_AGC_without_Preamp(n, nn) = results.with_AGC_without_Preamp.cumulative_NF(end);

      channel_processed_SNR.without_AGC_with_Preamp(n, nn) = results.without_AGC_with_Preamp.processed_snr(end);
      channel_processed_SNR.without_AGC_without_Preamp(n, nn) = results.without_AGC_without_Preamp.processed_snr(end);
      channel_processed_SNR.with_AGC_with_Preamp(n, nn) = results.with_AGC_with_Preamp.processed_snr(end);
      channel_processed_SNR.with_AGC_without_Preamp(n, nn) = results.with_AGC_without_Preamp.processed_snr(end);

      sensitivity.without_AGC_with_Preamp(n, nn) = results.without_AGC_with_Preamp.sensitivity(end);
      sensitivity.without_AGC_without_Preamp(n, nn) = results.without_AGC_without_Preamp.sensitivity(end);
      sensitivity.with_AGC_with_Preamp(n, nn) = results.with_AGC_with_Preamp.sensitivity(end);
      sensitivity.with_AGC_without_Preamp(n, nn) = results.with_AGC_without_Preamp.sensitivity(end);
   end
end

% diagnostic_plots(Radio.without_AGC_with_Preamp, results.without_AGC_with_Preamp)
% diagnostic_plots(Radio.without_AGC_without_Preamp, results.without_AGC_without_Preamp)
% diagnostic_plots(Radio.with_AGC_with_Preamp, results.with_AGC_with_Preamp)
% diagnostic_plots(Radio.with_AGC_without_Preamp, results.with_AGC_without_Preamp)

effective_NF_without_AGC_with_Preamp = effective_NF.without_AGC_with_Preamp(n,:);
effective_NF_without_AGC_without_Preamp = effective_NF.without_AGC_without_Preamp(n,:);
effective_NF_with_AGC_with_Preamp = effective_NF.with_AGC_with_Preamp(n,:);
effective_NF_with_AGC_without_Preamp = effective_NF.with_AGC_without_Preamp(n,:);

figure1 = figure;
axes1 = axes('Parent',figure1);
hold(axes1,'on');
box(axes1,'on');
xlabel('Signal Power (dBm)');
ylabel('Effective NF (dB)');
title('Effective NF (dB) vs Signal and Interferer level');
set(axes1,'FontName','Times New Roman','XGrid','on','YGrid','on');
legend1 = legend(axes1,'show');
set(legend1,'Location','northwest','FontSize',10);

plot(axes1, desired_level_vector, effective_NF_without_AGC_with_Preamp, 'DisplayName','Effective NF (dB) without AGC an with pre-amp');
plot(axes1, desired_level_vector, effective_NF_without_AGC_without_Preamp, 'DisplayName','Effective NF (dB) without AGC an without pre-amp');
plot(axes1, desired_level_vector, effective_NF_with_AGC_with_Preamp, 'DisplayName','Effective NF (dB) with AGC an with pre-amp');
plot(axes1, desired_level_vector, effective_NF_with_AGC_without_Preamp, 'DisplayName','Effective NF (dB) with AGC an without pre-amp');

channel_processed_SNR_without_AGC_with_Preamp = channel_processed_SNR.without_AGC_with_Preamp(n,:);
channel_processed_SNR_without_AGC_without_Preamp = channel_processed_SNR.without_AGC_without_Preamp(n,:);
channel_processed_SNR_with_AGC_with_Preamp = channel_processed_SNR.with_AGC_with_Preamp(n,:);
channel_processed_SNR_with_AGC_without_Preamp = channel_processed_SNR.with_AGC_without_Preamp(n,:);

figure1 = figure;
axes1 = axes('Parent',figure1);
hold(axes1,'on');
box(axes1,'on');
xlabel('Signal Power (dBm)');
ylabel('Processed SNR (dB)');
title('Processed SNR (dB) vs Signal and Interferer level');
set(axes1,'FontName','Times New Roman','XGrid','on','YGrid','on');
legend1 = legend(axes1,'show');
set(legend1,'Location','northwest','FontSize',10);

plot(axes1, desired_level_vector, channel_processed_SNR_without_AGC_with_Preamp, 'DisplayName','Processed SNR (dB) without AGC an with pre-amp');
plot(axes1, desired_level_vector, channel_processed_SNR_without_AGC_without_Preamp, 'DisplayName','Processed SNR (dB) without AGC an without pre-amp');
plot(axes1, desired_level_vector, channel_processed_SNR_with_AGC_with_Preamp, 'DisplayName','Processed SNR (dB) with AGC an with pre-amp');
plot(axes1, desired_level_vector, channel_processed_SNR_with_AGC_without_Preamp, 'DisplayName','Processed SNR (dB) with AGC an without pre-amp');

sensitivity_without_AGC_with_Preamp = sensitivity.without_AGC_with_Preamp(n,:);
sensitivity_without_AGC_without_Preamp = sensitivity.without_AGC_without_Preamp(n,:);
sensitivity_with_AGC_with_Preamp = sensitivity.with_AGC_with_Preamp(n,:);
sensitivity_with_AGC_without_Preamp = sensitivity.with_AGC_without_Preamp(n,:);

figure1 = figure;
axes1 = axes('Parent',figure1);
hold(axes1,'on');
box(axes1,'on');
xlabel('Signal Power (dBm)');
ylabel('Sensitivity (dBm)');
title('Sensitivity (dBm) vs Signal and Interferer level');
set(axes1,'FontName','Times New Roman','XGrid','on','YGrid','on');
legend1 = legend(axes1,'show');
set(legend1,'Location','northwest','FontSize',10);

plot(axes1, desired_level_vector, sensitivity_without_AGC_with_Preamp, 'DisplayName','Sensitivity (dBm) without AGC an with pre-amp');
plot(axes1, desired_level_vector, sensitivity_without_AGC_without_Preamp, 'DisplayName','Sensitivity (dBm) without AGC an without pre-amp');
plot(axes1, desired_level_vector, sensitivity_with_AGC_with_Preamp, 'DisplayName','Sensitivity (dBm) with AGC an with pre-amp');
plot(axes1, desired_level_vector, sensitivity_with_AGC_without_Preamp, 'DisplayName','Sensitivity (dBm) with AGC an without pre-amp');

alpha = 1;
figure1 = figure;
axes1 = axes('Parent',figure1);
hold(axes1,'on');
box(axes1,'on');
xlabel('Signal Power (dBm)');
ylabel('Interferer Power (dBm)');
zlabel('Effective NF (dB)');
title('Effective NF (dB) vs Signal and Interferer level');
set(axes1,'FontName','Times New Roman','XGrid','on','YGrid','on');
legend1 = legend(axes1,'show');
set(legend1,'Location','northwest','FontSize',10);
s = surf(desired_level_vector, interferer_level_vector, effective_NF.without_AGC_with_Preamp, 'FaceAlpha', alpha, 'Parent', axes1, 'DisplayName','Effective NF (dB) without AGC an with pre-amp');
s.EdgeColor = 'none';
s.FaceColor = 'interp';
s = surf(desired_level_vector, interferer_level_vector, effective_NF.without_AGC_without_Preamp, 'FaceAlpha', alpha, 'Parent', axes1, 'DisplayName','Effective NF (dB) without AGC an without pre-amp');
s.EdgeColor = 'none';
s.FaceColor = 'interp';
s = surf(desired_level_vector, interferer_level_vector, effective_NF.with_AGC_with_Preamp, 'FaceAlpha', alpha, 'Parent', axes1, 'DisplayName','Effective NF (dB) with AGC an with pre-amp');
s.EdgeColor = 'none';
s.FaceColor = 'interp';
s = surf(desired_level_vector, interferer_level_vector, effective_NF.with_AGC_without_Preamp, 'FaceAlpha', alpha, 'Parent', axes1, 'DisplayName','Effective NF (dB) with AGC an without pre-amp');
s.EdgeColor = 'none';
s.FaceColor = 'interp';
set(axes1,'Colormap',...
   [0 0 0.515625;0 0 0.53125;0 0 0.546875;0 0 0.5625;0 0 0.578125;0 0 0.59375;0 0 0.609375;0 0 0.625;0 0 0.640625;0 0 0.65625;0 0 0.671875;0 0 0.6875;0 0 0.703125;0 0 0.71875;0 0 0.734375;0 0 0.75;0 0 0.765625;0 0 0.78125;0 0 0.796875;0 0 0.8125;0 0 0.828125;0 0 0.84375;0 0 0.859375;0 0 0.875;0 0 0.890625;0 0 0.90625;0 0 0.921875;0 0 0.9375;0 0 0.953125;0 0 0.96875;0 0 0.984375;0 0 1;0 0.015625 1;0 0.03125 1;0 0.046875 1;0 0.0625 1;0 0.078125 1;0 0.09375 1;0 0.109375 1;0 0.125 1;0 0.140625 1;0 0.15625 1;0 0.171875 1;0 0.1875 1;0 0.203125 1;0 0.21875 1;0 0.234375 1;0 0.25 1;0 0.265625 1;0 0.28125 1;0 0.296875 1;0 0.3125 1;0 0.328125 1;0 0.34375 1;0 0.359375 1;0 0.375 1;0 0.390625 1;0 0.40625 1;0 0.421875 1;0 0.4375 1;0 0.453125 1;0 0.46875 1;0 0.484375 1;0 0.5 1;0 0.515625 1;0 0.53125 1;0 0.546875 1;0 0.5625 1;0 0.578125 1;0 0.59375 1;0 0.609375 1;0 0.625 1;0 0.640625 1;0 0.65625 1;0 0.671875 1;0 0.6875 1;0 0.703125 1;0 0.71875 1;0 0.734375 1;0 0.75 1;0 0.765625 1;0 0.78125 1;0 0.796875 1;0 0.8125 1;0 0.828125 1;0 0.84375 1;0 0.859375 1;0 0.875 1;0 0.890625 1;0 0.90625 1;0 0.921875 1;0 0.9375 1;0 0.953125 1;0 0.96875 1;0 0.984375 1;0 1 1;0.015625 1 0.984375;0.03125 1 0.96875;0.046875 1 0.953125;0.0625 1 0.9375;0.078125 1 0.921875;0.09375 1 0.90625;0.109375 1 0.890625;0.125 1 0.875;0.140625 1 0.859375;0.15625 1 0.84375;0.171875 1 0.828125;0.1875 1 0.8125;0.203125 1 0.796875;0.21875 1 0.78125;0.234375 1 0.765625;0.25 1 0.75;0.265625 1 0.734375;0.28125 1 0.71875;0.296875 1 0.703125;0.3125 1 0.6875;0.328125 1 0.671875;0.34375 1 0.65625;0.359375 1 0.640625;0.375 1 0.625;0.390625 1 0.609375;0.40625 1 0.59375;0.421875 1 0.578125;0.4375 1 0.5625;0.453125 1 0.546875;0.46875 1 0.53125;0.484375 1 0.515625;0.5 1 0.5;0.515625 1 0.484375;0.53125 1 0.46875;0.546875 1 0.453125;0.5625 1 0.4375;0.578125 1 0.421875;0.59375 1 0.40625;0.609375 1 0.390625;0.625 1 0.375;0.640625 1 0.359375;0.65625 1 0.34375;0.671875 1 0.328125;0.6875 1 0.3125;0.703125 1 0.296875;0.71875 1 0.28125;0.734375 1 0.265625;0.75 1 0.25;0.765625 1 0.234375;0.78125 1 0.21875;0.796875 1 0.203125;0.8125 1 0.1875;0.828125 1 0.171875;0.84375 1 0.15625;0.859375 1 0.140625;0.875 1 0.125;0.890625 1 0.109375;0.90625 1 0.09375;0.921875 1 0.078125;0.9375 1 0.0625;0.953125 1 0.046875;0.96875 1 0.03125;0.984375 1 0.015625;1 1 0;1 0.984375 0;1 0.96875 0;1 0.953125 0;1 0.9375 0;1 0.921875 0;1 0.90625 0;1 0.890625 0;1 0.875 0;1 0.859375 0;1 0.84375 0;1 0.828125 0;1 0.8125 0;1 0.796875 0;1 0.78125 0;1 0.765625 0;1 0.75 0;1 0.734375 0;1 0.71875 0;1 0.703125 0;1 0.6875 0;1 0.671875 0;1 0.65625 0;1 0.640625 0;1 0.625 0;1 0.609375 0;1 0.59375 0;1 0.578125 0;1 0.5625 0;1 0.546875 0;1 0.53125 0;1 0.515625 0;1 0.5 0;1 0.484375 0;1 0.46875 0;1 0.453125 0;1 0.4375 0;1 0.421875 0;1 0.40625 0;1 0.390625 0;1 0.375 0;1 0.359375 0;1 0.34375 0;1 0.328125 0;1 0.3125 0;1 0.296875 0;1 0.28125 0;1 0.265625 0;1 0.25 0;1 0.234375 0;1 0.21875 0;1 0.203125 0;1 0.1875 0;1 0.171875 0;1 0.15625 0;1 0.140625 0;1 0.125 0;1 0.109375 0;1 0.09375 0;1 0.078125 0;1 0.0625 0;1 0.046875 0;1 0.03125 0;1 0.015625 0;1 0 0;0.984375 0 0;0.96875 0 0;0.953125 0 0;0.9375 0 0;0.921875 0 0;0.90625 0 0;0.890625 0 0;0.875 0 0;0.859375 0 0;0.84375 0 0;0.828125 0 0;0.8125 0 0;0.796875 0 0;0.78125 0 0;0.765625 0 0;0.75 0 0;0.734375 0 0;0.71875 0 0;0.703125 0 0;0.6875 0 0;0.671875 0 0;0.65625 0 0;0.640625 0 0;0.625 0 0;0.609375 0 0;0.59375 0 0;0.578125 0 0;0.5625 0 0;0.546875 0 0;0.53125 0 0;0.515625 0 0;0.5 0 0]);
view(axes1,[-25 35]);

effective_NF_without_AGC_with_Preamp = effective_NF.without_AGC_with_Preamp;
effective_NF_without_AGC_without_Preamp = effective_NF.without_AGC_without_Preamp;
effective_NF_with_AGC_with_Preamp = effective_NF.with_AGC_with_Preamp;
effective_NF_with_AGC_without_Preamp = effective_NF.with_AGC_without_Preamp;

channel_processed_SNR_without_AGC_with_Preamp = channel_processed_SNR.without_AGC_with_Preamp;
channel_processed_SNR_without_AGC_without_Preamp = channel_processed_SNR.without_AGC_without_Preamp;
channel_processed_SNR_with_AGC_with_Preamp = channel_processed_SNR.with_AGC_with_Preamp;
channel_processed_SNR_with_AGC_without_Preamp = channel_processed_SNR.with_AGC_without_Preamp;

sensitivity_without_AGC_with_Preamp = sensitivity.without_AGC_with_Preamp;
sensitivity_without_AGC_without_Preamp = sensitivity.without_AGC_without_Preamp;
sensitivity_with_AGC_with_Preamp = sensitivity.with_AGC_with_Preamp;
sensitivity_with_AGC_without_Preamp = sensitivity.with_AGC_without_Preamp;

save('Radio.mat', ...
     'desired_level_vector', ...
     'interferer_level_vector', ...
     'effective_NF_without_AGC_with_Preamp', ...
     'effective_NF_without_AGC_without_Preamp', ...
     'effective_NF_with_AGC_with_Preamp', ...
     'effective_NF_with_AGC_without_Preamp', ...
     'channel_processed_SNR_without_AGC_with_Preamp', ...
     'channel_processed_SNR_without_AGC_without_Preamp', ...
     'channel_processed_SNR_with_AGC_with_Preamp', ...
     'channel_processed_SNR_with_AGC_without_Preamp', ...
     'sensitivity_without_AGC_with_Preamp', ...
     'sensitivity_without_AGC_without_Preamp', ...
     'sensitivity_with_AGC_with_Preamp', ...
     'sensitivity_with_AGC_without_Preamp');
