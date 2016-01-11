function [ xoverKids ] = gacrossovercombineprior(parents, ~, GenomeLength, ~, ...
    ~, thisPopulation, xyz, volumeSize, bboxmin, bboxmax)
%GACROSSOVERCOMBINEPRIOR ga crossover operator
%   GACROSSOVERCOMBINEPRIOR uses the combineHeatMap8 function to generate
%   xoverKids from parents, it uses upheat and smoothness priors to select
%   to favor certain genes
%
%   See also COMBINEHEATMAP8.

% How many children to produce?
nKids = length(parents)/2;

% Allocate space for the kids
xoverKids = zeros(nKids,GenomeLength);

% Allocate space for the kids candidates
nCandidates = 10;
xoverCandidates = zeros(nCandidates,GenomeLength);

% To move through the parents twice as fast as thekids are
% being produced, a separate index for the parents is needed
index = 1;

for i=1:nKids
    % get parents
    parent1 = thisPopulation(parents(index),:);
    index = index + 1;
    parent2 = thisPopulation(parents(index),:);
    index = index + 1;
    
    % Try a few crossover at random and pick the candidate according to the
    % prior scores
    for j=1:nCandidates
        xoverCandidates(j,:) = combineHeatMap8(xyz, parent1', parent2', bboxmin, bboxmax)';
    end
    
    % The lower the value the smoother the volume is
    smooth_val = smoothnessEstimate(xyz, xoverCandidates, volumeSize);
    smooth_val = weights2prob(smooth_val, true);
    
    % Up heat val
    upheat_val = upHeatEstimate(xyz, xoverCandidates, volumeSize);
    upheat_val = weights2prob(upheat_val);
    
    % Relative weights for smoothness and upheat estimates,
    % must sum up to one
    smooth_k = 0.5;
    upheat_k = 0.5;
    
    total_prob = smooth_val * smooth_k + upheat_val * upheat_k;
    
    % Choose a kid with a probability proportional to a
    % combination of the prior estimates
    kid_idx = randsample(1:nCandidates, 1, true, total_prob);
    
    xoverKids(i,:) = xoverCandidates(kid_idx, :);
end
end

