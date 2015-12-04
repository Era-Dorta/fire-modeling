function [ result ] = getRandomInitPopulation( LB, UB, n )
% Generates a new population of size n in the LB and UB range of randomly
% selected individuals

% This function is meant to be used to initialize the
% options.InitialPopulation matrix in the GA solver
result = rand(n, size(LB, 2));
for i=1:n
    result(i,:) = fitToRange(result(i,:), 0, 1, LB, UB);
end
end
