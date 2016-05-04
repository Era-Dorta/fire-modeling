function [ prior_fncs, prior_weights, nCandidates ] = ...
    get_prior_fncs_from_file( L, init_heat_map, goal_img, ...
    goal_mask, lb, ub, fnc_type, fixed_size)
%GET_PRIOR_FNCS_FROM_FILE Sets GA operator options
%   [ PRIOR_FNCS, PRIOR_WEIGHTS, NCANDIDATES ] = GET_PRIOR_FNCS_FROM_FILE(
%   ARGS_PATH, INIT_HEAT_MAP, GOAL_IMG, GOAL_MASK, LB, UB, FNC_TYPE)
%
%   See also get_ga_options_from_file

switch(fnc_type)
    case 'fitness'
        prior_fncs = L.prior_fncs;
        prior_weights = L.prior_weights;
    case 'crossover'
        prior_fncs = L.xover_prior_fncs;
        prior_weights = L.xover_prior_weights;
        nCandidates = L.xover_nCandidates;
    case 'mutation'
        prior_fncs = L.mut_prior_fncs;
        prior_weights = L.mut_prior_weights;
        nCandidates = L.mut_nCandidates;
    otherwise
        error('Unkown load type');
end

num_prior_fncs = numel(prior_fncs);

for i=1:num_prior_fncs
    if isequal(prior_fncs{i}, @smoothnessEstimateGrad)
        
        if fixed_size
            prior_fncs{i} = @(v) smoothnessEstimateGrad(init_heat_map.xyz, v,  ...
                init_heat_map.size, lb, ub);
        else
            prior_fncs{i} = @(v, xyz, whd) smoothnessEstimateGrad(xyz, v,  ...
                whd, lb, ub);
        end
        
    elseif isequal(prior_fncs{i}, @upHeatEstimate)
        
        if fixed_size
            prior_fncs{i} = @(v) upHeatEstimate(init_heat_map.xyz, v, ...
                init_heat_map.size);
        else
            prior_fncs{i} = @(v, xyz, whd) upHeatEstimate(xyz, v, whd);
        end
        
    elseif isequal(prior_fncs{i}, @histogramErrorApprox)
        
        prior_fncs{i} = @(v) histogramErrorApprox(v, goal_img, goal_mask);
        
    else
        error(['Unkown prior function ' args_path]);
    end
    
end

