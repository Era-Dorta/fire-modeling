function [ mutationChildren ] = gamutationpermute(parents, ~, GenomeLength, ~, ...
    ~, thisPopulation)
%GAMUTATIONPERMUTE ga mutation operator
%   GAMUTATIONPERMUTE uses permutaions to generate xoverKids from parents
%

% How many children to produce?
nKids = length(parents);

% Allocate space for the kids
mutationChildren = thisPopulation;

for i=1:nKids
    % Get the parent
    parent = thisPopulation(parents(i),:);
    
    % Child is a random permutation of the parent
    mutationChildren(i,:) = parent(randperm(GenomeLength,GenomeLength));
end
end

