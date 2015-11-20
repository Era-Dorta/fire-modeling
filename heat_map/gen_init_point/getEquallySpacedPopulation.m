function [ result ] = getEquallySpacedPopulation( LB, UB, n )
% Generates a new population of size n in the LB and UB range, of uniformly
% space individuals where each of them has the same value for all dimensions
myfoo = @(x, y)linspace(x , y, n)';
result = cell2mat(arrayfun(myfoo, LB, UB, 'Uniform', false));
end