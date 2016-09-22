function t = generate_gaussian_temperatures_icm(i, x, optimValues, options, lb, ub)
% Generate temperatures
stdTemp = 200;
stdTemp = stdTemp - stdTemp * optimValues.iteration / options.MaxIterations;
t = normrnd(x(i), stdTemp, 1, options.TemperatureNSamples);
t = max(t, lb(i));
t = min(t, ub(i));
end