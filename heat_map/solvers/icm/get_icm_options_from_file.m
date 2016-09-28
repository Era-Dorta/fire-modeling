function [ options_out ] = get_icm_options_from_file( L, init_heat_map,  ...
    goal_img, goal_mask, output_data_path, paths_str, is_grad, fitness_foo, ...
    maya_send)
%GET_ICM_OPTIONS_FROM_FILE Sets ICM options
%   [ OPTIONS_OUT ] = GET_ICM_OPTIONS_FROM_FILE( ARGS_PATH, INIT_HEAT_MAP,
%      GOAL_IMG, GOAL_MASK, INIT_POPULATION_PATH, PATHS_STR) Given a mat
%   file path in ARGS_PATH, and the rest of arguments. Outputs a valid
%   gaoptimiset instance in OPTIONS_OUT
%
%   See also do_icm_solve

num_goal = numel(goal_img);

%% OutputFcn
for i=1:numel(L.options.OutputFcn)
    if isequal(L.options.OutputFcn{i}, @gradient_time_limit)
        startTime = tic;
        L.options.OutputFcn{i} = @(x, optimValues, state) gradient_time_limit(x, ...
            optimValues, state, L.time_limit, startTime);
    elseif isequal(L.options.OutputFcn{i}, @gradplotbestgen)
        L.options.OutputFcn{i} = @(x, optimValues, state) gradplotbestgen(x, ...
            optimValues, state, paths_str.ite_img, paths_str.output_folder, ...
            num_goal);
    elseif isequal(L.options.OutputFcn{i}, @gradsavescores)
        L.options.OutputFcn{i} = @(x, optimValues, state) gradsavescores(x, ...
            optimValues, state, output_data_path);
    elseif isequal(L.options.OutputFcn{i}, @gradploterror)
        L.options.OutputFcn{i} = @(x, optimValues, state) gradploterror(x, ...
            optimValues, state, paths_str.errorfig);
        
    elseif isequal(L.options.OutputFcn{i}, @gradestimate_density_scale)
        
        L.options.OutputFcn{i} = @(x, optimValues, state) ...
            gradestimate_density_scale(x, optimValues, state, ...
            maya_send, L, init_heat_map, fitness_foo,  ...
            paths_str.output_folder, num_goal);
        
        if L.use_cache
            error('use_cache must be set to false when using @gradestimate_density_scale');
        end
    else
        foo_str = func2str(L.options.OutputFcn{i});
        error(['Unkown outputFnc ' foo_str ' in do_icm_solve']);
    end
end

%% CreationFcn
valid_foo = {@random_guess_icm, @getInitHeatMap_icm, @getMeanTemp_icm, ...
    @getInitHeatMapScaled_icm};

if ~isequalFncCell(L.initGuessFnc, valid_foo)
    error(['Unkown ICM initGuessFnc @' func2str(L.initGuessFnc) ...
        ' in ' L.args_path]);
end

if is_grad
    options_out = L.options;
    return;
end

%% CreateSamplesFcn

valid_foo = { @generate_random_temperatures_icm, ...
    @generate_linspace_temperatures_icm, @generate_gaussian_temperatures_icm};

if ~isequalFncCell(L.options.CreateSamplesFcn, valid_foo)
    error(['Unkown ICM CreateSamplesFcn @' func2str(L.options.CreateSamplesFcn) ...
        ' in ' L.args_path]);
end

%% UpdateSampleRangeFcn

valid_foo = { @update_range_none_icm, ...
    @linear_range_reduce_temperature_icm};

if ~isequalFncCell(L.options.UpdateSampleRangeFcn, valid_foo)
    error(['Unkown ICM UpdateSampleRangeFcn @' func2str(L.options.UpdateSampleRangeFcn) ...
        ' in ' L.args_path]);
end

%% DataTermFcn
valid_foo =  {@zero_data_term_icm};

if numel(L.options.DataTermFcn) ~= numel(L.options.DataTermFactors)
    error(['ICM there are ' num2str(numel(L.options.DataTermFcn))  ...
        ' dataterm functions and ' num2str(numel(L.options.DataTermFactors)) ...
        ' but both must be the same']);
end

for i=1:numel(L.options.DataTermFcn)
    
    if isequal(L.options.DataTermFcn{i}, @eval_render_function_always_icm)
        
        L.options.DataTermFcn{i} = @( i, x,  options, ...
            optimValues, lb, ub) eval_render_function_always_icm ...
            (i, x,  options, optimValues, lb, ub, fitness_foo);
        
    else
        
        if ~isequalFncCell(L.options.DataTermFcn{i}, valid_foo)
            error(['Unkown ICM DataTermFcn @' func2str(L.options.DataTermFcn{i}) ...
                ' in ' L.args_path]);
        end
        
    end
    
end

%% DataTermApproxFcn
if isempty(L.options.DataTermApproxFactors)
    L.options.DataTermApproxFactors = L.options.DataTermFactors;
end

% If not specified, just copy from data term
if isempty(L.options.DataTermApproxFcn)
    L.options.DataTermApproxFcn = L.options.DataTermFcn;    
else
    valid_foo =  {@zero_data_term_icm};
    
    if numel(L.options.DataTermApproxFcn) ~= numel(L.options.DataTermApproxFactors)
        error(['ICM there are ' num2str(numel(L.options.DataTermApproxFcn))  ...
            ' dataterm functions and ' num2str(numel(L.options.DataTermApproxFactors)) ...
            ' but both must be the same']);
    end
    
    for i=1:numel(L.options.DataTermApproxFcn)
        
        if isequal(L.options.DataTermApproxFcn{i}, @eval_render_function_always_icm)
            
            L.options.DataTermApproxFcn{i} = @( i, x,  options, ...
                optimValues, lb, ub) eval_render_function_always_icm ...
                (i, x,  options, optimValues, lb, ub, fitness_foo);
            
        elseif isequal(L.options.DataTermApproxFcn{i}, @eval_render_function_half_ite_icm)
            
            L.options.DataTermApproxFcn{i} = @( i, x,  options, ...
                optimValues, lb, ub) eval_render_function_half_ite_icm ...
                (i, x,  options, optimValues, lb, ub, fitness_foo);
            
        else
            
            if ~isequalFncCell(L.options.DataTermApproxFcn{i}, valid_foo)
                error(['Unkown ICM DataTermApproxFcn @' func2str(L.options.DataTermApproxFcn{i}) ...
                    ' in ' L.args_path]);
            end
        end
    end
    
end
%% PairWiseTermFcn

if numel(L.options.PairWiseTermFcn) ~= numel(L.options.PairWiseTermFactors)
    error(['ICM there are ' num2str(numel(L.options.DataTermFcn))  ...
        ' pairwise term functions and ' num2str(numel(L.options.PairWiseTermFactors)) ...
        ' but both must be the same']);
end

valid_foo = {@neighbour_distance_term_icm, @zero_pairwise_score_icm, ...
    @neighbour_distance_exp_term_icm, @neighbour_distance_exp2_term_icm};

for i=1:numel(L.options.PairWiseTermFcn)
    
    if ~isequalFncCell(L.options.PairWiseTermFcn{i}, valid_foo)
        error(['Unkown ICM PairWiseTermFcn @' func2str(L.options.PairWiseTermFcn{i}) ...
            ' in ' L.args_path]);
    end
    
end

%% Return the full options struct
options_out = L.options;

end
