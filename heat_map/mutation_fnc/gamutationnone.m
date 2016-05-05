function [ mutationChildren ] = gamutationnone(parents, ~, ~, ~, ~, ~, thisPopulation)
%GAMUTATIONNONE GA mutation operator
%   [ mutationChildren ] = GAMUTATIONNONE(parents, options, nvars, ...
%   FitnessFcn, state, thisScore, thisPopulation)
%   The parents are directly copied as children
mutationChildren = thisPopulation(parents,:);
end

