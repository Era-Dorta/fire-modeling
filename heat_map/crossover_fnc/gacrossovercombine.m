function [ xoverKids ] = gacrossovercombine(parents, ~, GenomeLength, ~, ...
    ~, thisPopulation, xyz, bboxmin, bboxmax)
%GACROSSOVERCOMBINE ga crossover operator
%   GACROSSOVERCOMBINE uses the combineHeatMap8 function to generate
%   xoverKids from parents
%
%   See also COMBINEHEATMAP8.

% How many children to produce?
nKids = length(parents)/2;

% Allocate space for the kids
xoverKids = zeros(nKids,GenomeLength);

% To move through the parents twice as fast as thekids are
% being produced, a separate index for the parents is needed
index = 1;

for i=1:nKids
    % get parents
    parent1 = thisPopulation(parents(index),:);
    index = index + 1;
    parent2 = thisPopulation(parents(index),:);
    index = index + 1;
    
    xoverKids(i,:) = combineHeatMap8(xyz, parent1', parent2', bboxmin, bboxmax)';
end
end

