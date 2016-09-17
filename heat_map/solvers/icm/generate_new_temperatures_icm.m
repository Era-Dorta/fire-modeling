function t = generate_new_temperatures_icm(i, options, lb, ub)
% Generate temperatures
t = linspace(lb(i), ub(i), options.TemperatureNSamples);
end