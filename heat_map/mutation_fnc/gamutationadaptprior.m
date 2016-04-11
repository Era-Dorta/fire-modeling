function [ mutationChildren ] = gamutationadaptprior(parents, options, GenomeLength, ...
    FitnessFcn, state, thisScore, thisPopulation, xyz, volumeSize)
%GAMUTATIONADAPTPRIOR is a ga mutation function
%   [ mutationChildren ] = GAMUTATIONADAPTPRIOR(parents, options, GenomeLength, ...
%   FitnessFcn, state, thisScore, thisPopulation, xyz, volumeSize)
%   Like @mutationadaptfeasible but with smoothness and upheat priors on the
%   mutated children

persistent StepSize
% Binary strings always maintain feasibility
if(strcmpi(options.PopulationType,'bitString'))
    mutationChildren = mutationuniform(parents ,options, GenomeLength, ...
        FitnessFcn,state, thisScore,thisPopulation);
    return;
end

if state.Generation <=2
    StepSize = 1; % Initialization
else
    if isfield(state,'Spread')
        if state.Spread(end) > state.Spread(end-1)
            StepSize = min(1,StepSize*4);
        else
            StepSize = max(sqrt(eps),StepSize/4);
        end
    else
        if state.Best(end) < state.Best(end-1)
            StepSize = min(1,StepSize*4);
        else
            StepSize = max(sqrt(eps),StepSize/4);
        end
    end
end

scale = 1; % Using no scale
% Assume unconstrained sub-problem
feasible =true;

% Extract information about constraints
linCon = options.LinearConstr;
constr = ~isequal(linCon.type,'unconstrained');
tol = max(sqrt(eps),options.TolCon);
neqcstr = size(linCon.Aeq,1) ~= 0;
% Initialize childrens
mutationChildren = zeros(length(parents),GenomeLength);

% Create childrens for each parents
for i=1:length(parents)
    x = thisPopulation(parents(i),:)';
    
    % Scale the variables (if needed)
    if neqcstr
        scale = logscale(linCon.lb,linCon.ub,mean(x,2));
    end
    %Get the directons which forms the positive basis(minimal or maximal basis)
    switch linCon.type
        case 'unconstrained'
            Basis = uncondirections(true,StepSize,x);
            TangentCone = [];
            constr = false;
        case 'boundconstraints'
            [Basis,TangentCone] = boxdirections(true,StepSize,x,linCon.lb,linCon.ub,tol);
            % If the point is on the constraint boundary (nonempty TangentCone)
            % we use scale = 1
            if ~isempty(TangentCone)
                scale = 1;
                TangentCone(:,(~any(TangentCone))) = [];
            end
        case 'linearconstraints'
            try
                [Basis,TangentCone] = lcondirections(true,StepSize,x,linCon.Aineq,linCon.bineq, ...
                    linCon.Aeq,linCon.lb,linCon.ub,tol);
            catch
                Basis = [];
                TangentCone = [];
            end
            % If the point is on the constraint boundary (nonempty TangentCone)
            % we use scale = 1
            if ~isempty(TangentCone)
                scale = 1;
                TangentCone(:,(~any(TangentCone))) = [];
            end
    end
    nDirTan = size(TangentCone,2);
    nBasis = size(Basis,2);
    % Add tangent cone to the direction vectors
    DirVector = [Basis TangentCone];
    % Total number of search directions
    nDirTotal = nDirTan + nBasis;
    % Make the index vector to be used to access directions
    indexVec = [1:nBasis 1:nBasis (nBasis+1):nDirTotal (nBasis+1):nDirTotal];
    % Vector to take care of sign of directions
    dirSign = [ones(1,nBasis) -ones(1,nBasis) ones(1,nDirTan) -ones(1,nDirTan)];
    OrderVec = randperm(length(indexVec));
    % Total number of trial points
    numberOfXtrials = length(OrderVec);
    % Check of empty trial points
    if (numberOfXtrials ~= 0)
        mutantCandidates = zeros(10, GenomeLength);
        numCandidates = 0;
        for k = 1:numberOfXtrials
            direction = dirSign(k).*DirVector(:,indexVec(OrderVec(k)));
            mutant = x + StepSize*scale.*direction;
            % Make sure mutant is feasible w.r.t. linear constraints else do not accept
            if constr
                feasible = isTrialFeasible(mutant,linCon.Aineq,linCon.bineq,linCon.Aeq, ...
                    linCon.beq,linCon.lb,linCon.ub,tol);
            end
            if feasible
                numCandidates = numCandidates + 1;
                mutantCandidates(numCandidates,:) = mutant';
                if(numCandidates == 10)
                    break;
                end
            end
        end
        if(numCandidates > 0)
            % If there is only one candidate do not bother computing the
            % prior estimates
            if(numCandidates == 1)
                mutationChildren(i,:) = mutantCandidates(1,:);
            else
                % The lower the value the smoother the volume is
                smooth_val = smoothnessEstimateGrad(xyz, mutantCandidates, ...
                    volumeSize,  options.LinearConstr.lb(1), ...
                    options.LinearConstr.ub(1));
                
                % Low values -> smoother -> higher weights
                smooth_val = weights2prob(smooth_val, true);
                
                % Up heat val
                upheat_val = upHeatEstimate(xyz, mutantCandidates, volumeSize);
                
                % High values -> more heat up -> higher weights
                upheat_val = weights2prob(upheat_val);
                
                % Relative weights for smoothness and upheat estimates,
                % must sum up to one
                smooth_k = 0.5;
                upheat_k = 0.5;
                
                total_prob = smooth_val * smooth_k + upheat_val * upheat_k;
                
                % Choose a mutant with a probability proportional to a
                % combination of the prior estimates
                mutant_idx = randsample(1:numCandidates, 1, true, total_prob);
                
                mutationChildren(i,:) = mutantCandidates(mutant_idx, :);
            end
        else
            mutationChildren(i,:) = x';
        end
    else
        mutationChildren(i,:) = x';
    end
end
end
