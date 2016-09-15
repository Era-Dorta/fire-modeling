function [ xoverKids ] = gacrossovercombine2(parents, ~, GenomeLength, ~, ...
    ~, thisPopulation, xyz, bboxmin, bboxmax)
%GACROSSOVERCOMBINE2 ga crossover operator
%   GACROSSOVERCOMBINE2 uses the combineHeatMap2point function to generate
%   xoverKids from parents
%
%   See also COMBINEHEATMAP2POINT.

persistent FixSeed

if(isempty(FixSeed) || FixSeed == false)
    warning('Disable fixed seed in gacrossovercombine2');
    FixSeed = true;
end

% How many children to produce?
nKids = length(parents)/2;

% Allocate space for the kids
xoverKids = zeros(nKids,GenomeLength);

% To move through the parents twice as fast as thekids are
% being produced, a separate index for the parents is needed
index = 1;

% Substitute values instead of interpolating
weight = 0;

for i=1:nKids
    % get parents
    parent1 = thisPopulation(parents(index),:);
    index = index + 1;
    parent2 = thisPopulation(parents(index),:);
    index = index + 1;
    
    xoverKids(i,:) = combineHeatMap2point(xyz, parent1', parent2', ...
        bboxmin, bboxmax, weight, randi([0,1e8]))';
end
end

