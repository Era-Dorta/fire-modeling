function [ result ] = random_guess_icm( ~, LB, UB )
%RANDOM_GUESS_ICM

% This function is meant to be used to initialize the
% options.InitialPopulation matrix in the GA solver
result = rand(1, size(LB, 2));
result = fitToRange(result, 0, 1, LB, UB);
end
