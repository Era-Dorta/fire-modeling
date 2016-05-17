function [ prior_fncs, prior_weights, nCandidates ] = ...
    get_prior_fncs_from_file( L, init_heat_map, goal_img, ...
    goal_mask, fnc_type, fixed_size)
%GET_PRIOR_FNCS_FROM_FILE Sets GA operator options
%   [ PRIOR_FNCS, PRIOR_WEIGHTS, NCANDIDATES ] = GET_PRIOR_FNCS_FROM_FILE(
%   L, INIT_HEAT_MAP, GOAL_IMG, GOAL_MASK, FNC_TYPE)
%
%   See also get_ga_options_from_file

switch(fnc_type)
    case 'fitness'
        prior_fncs = L.prior_fncs;
        prior_weights = L.prior_weights;
        temp_th = L.temp_th;
    case 'crossover'
        prior_fncs = L.xover_prior_fncs;
        prior_weights = L.xover_prior_weights;
        nCandidates = L.xover_nCandidates;
        temp_th = L.xover_temp_th;
    case 'mutation'
        prior_fncs = L.mut_prior_fncs;
        prior_weights = L.mut_prior_weights;
        nCandidates = L.mut_nCandidates;
        temp_th = L.mut_temp_th;
    otherwise
        error('Unkown load type');
end

num_prior_fncs = numel(prior_fncs);

for i=1:num_prior_fncs
    if isequal(prior_fncs{i}, @smoothnessEstimateGrad)
        
        if fixed_size
            prior_fncs{i} = @(v) smoothnessEstimateGrad(init_heat_map.xyz, v,  ...
                init_heat_map.size, L.LB, L.UB);
        else
            prior_fncs{i} = @(v, xyz, whd) smoothnessEstimateGrad(xyz, v,  ...
                whd, L.LB, L.UB);
        end
        
    elseif isequal(prior_fncs{i}, @upHeatEstimate)
        
        if fixed_size
            prior_fncs{i} = @(v) upHeatEstimate(init_heat_map.xyz, v, ...
                init_heat_map.size);
        else
            prior_fncs{i} = @(v, xyz, whd) upHeatEstimate(xyz, v, whd);
        end
        
    elseif isequal(prior_fncs{i}, @upHeatEstimateLinear)
        
        if fixed_size
            prior_fncs{i} = @(v) upHeatEstimateLinear(init_heat_map.xyz, v, ...
                init_heat_map.size, temp_th, L.LB, L.UB);
        else
            prior_fncs{i} = @(v, xyz, whd) upHeatEstimateLinear(xyz, v, whd, ...
                temp_th, L.LB, L.UB);
        end
        
    elseif isequal(prior_fncs{i}, @histogramErrorApprox)
        
        prior_fncs{i} = @(v) histogramErrorApprox(v, goal_img, goal_mask, ...
            L.fuel_type, L.color_space);
        
    else
        error(['Unkown prior function ' args_path]);
    end
    
end

