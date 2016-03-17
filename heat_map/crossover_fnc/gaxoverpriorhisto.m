function [ xoverKids ] = gaxoverpriorhisto(parents, options, GenomeLength, ~, ...
    thisScore, thisPopulation, xyz, volumeSize, bboxmin, bboxmax, goal_img, goal_mask)
%GAXOVERPRIORHISTO ga crossover operator
%   GAXOVERPRIORHISTO uses the combineHeatMap8 function to generate
%   xoverKids from parents, it uses upheat, smoothness and histogram priors
%   to select to favor certain genes, use only if histogram error function
%   is used in the fitness function
%
%   See also COMBINEHEATMAP8, GACROSSOVERCOMBINEPRIOR.

persistent FixSeed

if(isempty(FixSeed) || FixSeed == false)
    warning('Disable fixed seed in combineHeatMap8 for the final version');
    FixSeed = true;
end

% How many children to produce?
nKids = length(parents)/2;

% Allocate space for the kids
xoverKids = zeros(nKids,GenomeLength);

% Allocate space for the kids candidates
nCandidates = 10;
xoverCandidates = zeros(nCandidates,GenomeLength);

% To move through the parents twice as fast as the kids are
% being produced, a separate index for the parents is needed
index = 1;

for i=1:nKids
    % get parents
    parent1 = thisPopulation(parents(index),:);
    score1 = thisScore(parents(index));
    index = index + 1;
    parent2 = thisPopulation(parents(index),:);
    score2 = thisScore(parents(index));
    index = index + 1;
    
    % Get a 0..1 weight for the first parent using to both parents scores
    weight =  score1 / (score1 + score2);
    
    % Try a few random crossover giving more priority to the genes of the
    % parent with the higher score (weight)
    for j=1:nCandidates
        if(FixSeed)
            % For testing use a rand here to deviate the weight randomly,
            % and a fixed seed in combineHeatMap8
            weight = rand(1);
        end
        xoverCandidates(j,:) = combineHeatMap8(xyz, parent1', parent2', ...
            bboxmin, bboxmax, weight)';
    end
    
    % A smoothness estimate of the volume
    smooth_val = smoothnessEstimateGrad(xyz, xoverCandidates, volumeSize, ...
        options.LinearConstr.ub(1), options.LinearConstr.lb(1));
    
    % Low values -> smoother -> higher weights
    smooth_val = weights2prob(smooth_val, true);
    
    % Up heat value estimate
    upheat_val = upHeatEstimate(xyz, xoverCandidates, volumeSize);
    
    % High values -> more heat up -> higher weights
    upheat_val = weights2prob(upheat_val);
    
    % A estimate of the histogram error for the final image
    hist_val = histogramEstimate(xyz, xoverCandidates, volumeSize, goal_img, ...
        goal_mask);
    
    % Low values -> less error -> higher weights
    hist_val = weights2prob(hist_val, true);
    
    % Relative weights for smoothness and upheat estimates,
    % must sum up to one
    smooth_k = 1 / 3;
    upheat_k = 1 / 3;
    hist_k = 1 / 3;
    
    total_prob = smooth_val * smooth_k + upheat_val * upheat_k + ... 
        hist_val * hist_k;
    
    % Choose a kid randomly with a probability proportional to a
    % combination of the prior estimates
    kid_idx = randsample(1:nCandidates, 1, true, total_prob);
    
    xoverKids(i,:) = xoverCandidates(kid_idx, :);
end
end

