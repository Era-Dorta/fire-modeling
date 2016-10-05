function [ score, optimValues ] = zero_data_term_icm( ~, x, ~, ...
    optimValues, ~, ~)
%ZERO_DATA_TERM_ICM Score is zero always
score = zeros(1, size(x, 1));
end
