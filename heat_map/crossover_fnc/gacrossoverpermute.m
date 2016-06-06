function [ xoverKids ] = gacrossoverpermute(parents, ~, GenomeLength, ~, ...
    ~, thisPopulation)
%GACROSSOVERPERMUTE ga crossover operator
%   GACROSSOVERPERMUTE uses permutaions to generate xoverKids from parents
%

% How many children to produce?
nKids = length(parents)/2;

% Allocate space for the kids
xoverKids = zeros(nKids,GenomeLength);

% To move through the parents twice as fast as thekids are
% being produced, a separate index for the parents is needed
index = 1;

for i=1:nKids
    % Get first parent, ignore second one
    parent = thisPopulation(parents(index),:);
    index = index + 2;
    
    % Child is a random permutation of the parent
    xoverKids(i,:) = parent(randperm(GenomeLength,GenomeLength));
end
end

