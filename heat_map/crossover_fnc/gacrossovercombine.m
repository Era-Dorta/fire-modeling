function [ xoverKids ] = gacrossovercombine(parents, ~, GenomeLength, ~, ...
    ~, thisPopulation, xyz, bboxmin, bboxmax)
%GACROSSOVERCOMBINE ga crossover operator
%   GACROSSOVERCOMBINE uses the combineHeatMap8 function to generate
%   xoverKids from parents
%
%   See also COMBINEHEATMAP8.

persistent FixSeed

if(isempty(FixSeed) || FixSeed == false)
    warning('Disable fixed seed in combineHeatMap8');
    FixSeed = true;
end

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
    
    % Combine the heatmaps with equal probabilities
    weight = 0.5;
    
    if(FixSeed)
        % For testing use a rand here to deviate the weight randomly,
        % and a fixed seed in combineHeatMap8
        weight = rand(1);
    end
    xoverKids(i,:) = combineHeatMap8(xyz, parent1', parent2', bboxmin, bboxmax, weight)';
end
end

