function [ mutationChildren ] = gamutationnone(parents, ~, ~, ~, ~, ~, thisPopulation)
%GAMUTATIONNONE ga mutation that does not mutate
%   [ mutationChildren ] = GAMUTATIONNONE(parents, options, nvars, ...
%   FitnessFcn, state, thisScore, thisPopulation)
%   The parents are directly copied as children
mutationChildren = thisPopulation(parents,:);
end

