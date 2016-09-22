function t = generate_linspace_temperatures_icm(i, x, optimValues, options, lb, ub)
% Generate temperatures
t = linspace(lb(i), ub(i), options.TemperatureNSamples);
end