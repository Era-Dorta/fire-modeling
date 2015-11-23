function [ InitialPopulation ] = gacreationrandom( GenomeLength, FitnessFcn, ...
    options, savePath )
% Generates a new population of randomly chosen individuals

InitialPopulation = gacreationuniform(GenomeLength, FitnessFcn, options);

if nargin == 4
    save(savePath, 'InitialPopulation');
end
end
