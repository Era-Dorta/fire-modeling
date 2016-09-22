function t = generate_random_temperatures_icm(i, x, optimValues, options, lb, ub)
% Generate temperatures
t = rand(1, options.TemperatureNSamples);
t = fitToRange(t, 0, 1, lb(i), ub(i));
end