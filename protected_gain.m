function [signal_gain] = protected_gain(cascade, signal_in_dBm, secondary_signal_in_dBm)
   signal_gain = cascade.apparent_signal_gain(signal_in_dBm, secondary_signal_in_dBm);
   %if (signal_gain ~= 0) && ((imag(signal_gain) ~= 0) || ((cascade.gain - real(signal_gain)) >= cascade.destruction_compression))
   if (signal_gain ~= 0) && ((imag(signal_gain) ~= 0) || ((cascade.gain - signal_gain) >= cascade.destruction_compression))
%       error('cascade.gain %d \nimag() %d \nreal() %d \nabs %d \npin %d \nsspin %d \ncompression %d', cascade.gain, ...
%                                                                                                      imag(signal_gain), ...
%                                                                                                      real(signal_gain), ...
%                                                                                                      abs(signal_gain), ...
%                                                                                                      signal_in_dBm, ...
%                                                                                                      secondary_signal_in_dBm, ...
%                                                                                                      uncorrelated_power_combine([signal_in_dBm, secondary_signal_in_dBm]) + cascade.gain - cascade.pout);
      error('You have destroyed compnent %s as it is in %d dB compression', cascade.name, uncorrelated_power_combine([signal_in_dBm, secondary_signal_in_dBm]) + cascade.gain - cascade.pout);
      %Fail to open is more realistic for an amp
      signal_gain = -Inf;
      %Fail to short allows cascade to compute at least
      %signal_gain = 0;
      %Only way to get accurate headroom calculations when experiencing
      %destruction
      %signal_gain = cascade.gain;
   end
end