function t = generate_gaussian_temperatures_icm(i, x, optimValues, options, lb, ub)
% Generate temperatures
options.GenTempStd = options.GenTempStd - options.GenTempStd * ...
    optimValues.iteration / options.MaxIterations;
t = normrnd(x(i), options.GenTempStd, 1, options.TemperatureNSamples);
t = max(t, lb(i));
t = min(t, ub(i));
end