function [ result ] = getEquallySpacedPopulation( LB, UB, n )
% Generates a new population of size n in the LB and UB range, of uniformly
% space individuals where each of them has the same value for all dimensions

% This function is meant to be used to initialize the
% options.InitialPopulation matrix in the GA solver
myfoo = @(x, y)linspace(x , y, n)';
result = cell2mat(arrayfun(myfoo, LB, UB, 'Uniform', false));
end