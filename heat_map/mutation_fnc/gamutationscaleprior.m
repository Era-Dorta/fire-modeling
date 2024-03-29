function [ mutationChildren ] = gamutationscaleprior(parents, options, GenomeLength, ...
    ~, state, ~, thisPopulation, prior_fncs, prior_weights, ...
    numCandidates, mut_rate)
%GAMUTATIONSCALEPRIOR GA mutation operator
%   [ MUTATIONCHILDREN ] = GAMUTATIONSCALEPRIOR(PARENTS, OPTIONS, GENOMELENGTH,
%   FITNESSFCN, STATE, THISSCORE, THISPOPULATION, PRIOR_FNCS, PRIOR_WEIGHTS,
%   NUMCANDIDATES, MUT_RATE)
%   Similar to @mutationadaptfeasible, with added custom scale and prior
%   functions
%
%    See also mutationadaptfeasible, smoothnessEstimateGrad, upHeatEstimate
%    args_test_solver_template

persistent StepSize

if state.Generation <=2
    StepSize = 1; % Initialization
else
    if state.Best(end) < state.Best(end-1)
        % Fitness decreasing, optimizing is going well so increase the
        % mutation rate to maintain genetic diversity
        StepSize = min(1,StepSize*4);
    else
        % Fitness stale or increasing, decrease mutation rate to fine tune
        % gene values
        StepSize = max(sqrt(eps),StepSize/4);
    end
end

% Extract information about constraints
linCon = options.LinearConstr;

% Using a scale appropiate to our bounds, assume that the mean of the
% bounds is representative for the scale in the mutations
scale = abs(mean(linCon.lb) - mean(linCon.ub))/4;

% Initialize childrens
mutationChildren = zeros(length(parents),GenomeLength);

num_prior_fncs = numel(prior_fncs);
prior_vals = zeros(num_prior_fncs, numCandidates);

total_size = numCandidates * GenomeLength;
num_m_genes = ceil(mut_rate * numCandidates * GenomeLength);
if mod(num_m_genes, 2) ~=  0
    % Make total number of genes to be mutated an even number,
    % effectively makes the mutation rate higher, but for high dimensional
    % data the bias is negligible
    num_m_genes = num_m_genes + 1;
end

% Create childrens for each parents
for i=1:length(parents)
    x = thisPopulation(parents(i),:);
    
    % Repeat the original individual numCandidates times
    mutantCandidates = repmat(x, numCandidates, 1);
    
    % Increase the temperature of half of the genes to be mutated,
    % genes are randomly chosen from all the candidates
    mut_idx = randi(total_size, num_m_genes / 2, 1);
    mutantCandidates(mut_idx) = mutantCandidates(mut_idx) + StepSize*scale;
    
    % Decrease the temperature
    mut_idx = randi(total_size, num_m_genes / 2, 1);
    mutantCandidates(mut_idx) = mutantCandidates(mut_idx) - StepSize*scale;
    
    % Clamp to lower and upper bounds
    mutantCandidates = bsxfun(@max, mutantCandidates, options.LinearConstr.lb');
    mutantCandidates = bsxfun(@min, mutantCandidates, options.LinearConstr.ub');
    
    prior_vals(:) = 0;
    for j=1:num_prior_fncs
        prior_vals(j,:) = prior_fncs{j}(mutantCandidates);
        prior_vals(j,:) = weights2prob(prior_vals(j,:), true);
    end
    
    total_prob = prior_weights * prior_vals;
    
    % Choose a mutant with a probability proportional to a
    % combination of the prior estimates
    mutant_idx = randsample(1:numCandidates, 1, true, total_prob);
    
    mutationChildren(i,:) = mutantCandidates(mutant_idx, :);
    
end
end
