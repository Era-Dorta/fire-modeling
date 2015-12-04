function [ mutationChildren ] = gamutationmean(parents, options, nvars, ...
    FitnessFcn, state, thisScore, thisPopulation)
% Ga mutation function that generates mutations using the voxel means
%   Any mutation that is generated will not exceed the range of 
%   [m - min ... m + max] where m is the mean of the values of the
%   neighbours of the voxel and min and max are user defined parameters
    options
    mutationChildren = thisPopulation;
end

