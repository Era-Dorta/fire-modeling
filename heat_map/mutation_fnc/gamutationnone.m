function [ mutationChildren ] = gamutationnone(~, ~, ~, ~, ~, ~, thisPopulation)
%GAMUTATIONNONE ga mutation that does not mutate
%   [ mutationChildren ] = GAMUTATIONMEAN(parents, options, nvars, ...
%   FitnessFcn, state, thisScore, thisPopulation)
%   The parents are directly copied as children
mutationChildren = thisPopulation;
end

