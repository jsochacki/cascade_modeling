function [result_dBm] = uncorrelated_power_combine(dBm_vector)
for n = 1:1:max(size(dBm_vector))
   linear_power(n) = power(10, dBm_vector(n) / 10);
end
result_dBm = 10*log10(sum(linear_power));
end