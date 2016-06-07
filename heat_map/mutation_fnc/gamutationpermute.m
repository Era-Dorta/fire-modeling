function [ mutationChildren ] = gamutationpermute(parents, ~, GenomeLength, ...
    ~, ~, ~, thisPopulation, priorFncs, priorWeights, numCandidates, mutRate)
%GAMUTATIONPERMUTE ga mutation operator
%   GAMUTATIONPERMUTE uses permutaions to generate xoverKids from parents
%

% How many children to produce?
nKids = length(parents);

% Allocate space for the kids
mutationChildren = thisPopulation;

numMgenes = ceil(mutRate * GenomeLength);

numPriorFncs = numel(priorFncs);
priorVals = zeros(numPriorFncs, numCandidates);

for i=1:nKids
    % Repeat the original individual numCandidates times
    mutantCandidates = repmat(thisPopulation(parents(i),:), numCandidates, 1);
    
    % Child is a random permutation of the parent
    for j=1:numCandidates
        % Generate a list of unique gene indices
        genesIdx = randperm(GenomeLength, numMgenes*2);
        
        % Swap the position of the first half with the position of the
        % second half
        mutantCandidates(j,genesIdx(1:numMgenes)) = ...
            thisPopulation(parents(i),genesIdx(numMgenes+1:end));
        
        mutantCandidates(j,genesIdx(numMgenes+1:end)) = ...
            thisPopulation(parents(i),genesIdx(1:numMgenes));
    end
    
    % Evaluate prior_fncs for the candidates
    priorVals(:) = 0;
    for j=1:numPriorFncs
        priorVals(j,:) = priorFncs{j}(mutantCandidates);
        priorVals(j,:) = weights2prob(priorVals(j,:), true);
    end
    
    totalProb = priorWeights * priorVals;
    
    % Choose a mutant with a probability proportional to a
    % combination of the prior estimates
    mutantIdx = randsample(1:numCandidates, 1, true, totalProb);
    
    mutationChildren(i,:) = mutantCandidates(mutantIdx, :);
end
end

