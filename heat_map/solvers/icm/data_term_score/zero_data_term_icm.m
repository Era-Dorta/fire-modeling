function [ score, optimValues ] = zero_data_term_icm( ~, ~,  options, ...
    optimValues, ~, ~)
%ZERO_DATA_TERM_ICM Score is zero always
score = zeros(1, options.TemperatureNSamples);
end
