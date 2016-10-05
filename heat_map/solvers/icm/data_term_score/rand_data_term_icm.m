function [ score, optimValues ] = rand_data_term_icm( x, ~,  ~, ...
    optimValues, ~, ~)
%RAND_DATA_TERM_ICM Score is an array of random numbers {0,1}
score = rand(1, size(x, 1));
end
