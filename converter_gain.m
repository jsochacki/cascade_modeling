function [signal_gain] = converter_gain(cascade, signal_in_dBm, secondary_signal_in_dBm)
   temp = [signal_in_dBm, secondary_signal_in_dBm];
   total_power = uncorrelated_power_combine(temp);
   converter_saturation_dBm = (cascade.IP1dB - 1);
   if total_power <= converter_saturation_dBm
      signal_gain = 0;
   else
      signal_gain = converter_saturation_dBm - total_power;
   end
   if ((-signal_gain) >= cascade.destruction_compression)
%       warning('cascade.gain %d \nimag() %d \nreal() %d \nabs %d \npin %d \nsspin %d \ncompression %d', cascade.gain, ...
%                                                                                                      imag(signal_gain), ...
%                                                                                                      real(signal_gain), ...
%                                                                                                      abs(signal_gain), ...
%                                                                                                      signal_in_dBm, ...
%                                                                                                      secondary_signal_in_dBm, ...
%                                                                                                      uncorrelated_power_combine([signal_in_dBm, secondary_signal_in_dBm]) + cascade.gain - cascade.pout);
      warning('You have destroyed compnent %s as it is in %d dB compression', cascade.name, uncorrelated_power_combine([signal_in_dBm, secondary_signal_in_dBm]) + cascade.gain - cascade.pout);
      %Fail to open is more realistic for a converter
      signal_gain = -Inf;
      %Fail to short allows cascade to compute at least
      %signal_gain = 0;
      %Only way to get accurate headroom calculations when experiencing
      %destruction
      %signal_gain = cascade.gain;
   end
end