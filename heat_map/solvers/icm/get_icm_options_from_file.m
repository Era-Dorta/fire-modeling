function [ options_out ] = get_icm_options_from_file( L, init_heat_map,  ...
    goal_img, goal_mask, output_data_path, paths_str, use_first, fitness_foo)
%GET_ICM_OPTIONS_FROM_FILE Sets ICM options
%   [ OPTIONS_OUT ] = GET_ICM_OPTIONS_FROM_FILE( ARGS_PATH, INIT_HEAT_MAP,
%      GOAL_IMG, GOAL_MASK, INIT_POPULATION_PATH, PATHS_STR) Given a mat
%   file path in ARGS_PATH, and the rest of arguments. Outputs a valid
%   gaoptimiset instance in OPTIONS_OUT
%
%   See also do_icm_solve

num_goal = numel(goal_img);

%% CreateSamplesFcn

valid_foo = { @generate_random_temperatures_icm, ...
    @generate_linspace_temperatures_icm};

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

%% PairWiseTermFcn

if numel(L.options.PairWiseTermFcn) ~= numel(L.options.PairWiseTermFactors)
    error(['ICM there are ' num2str(numel(L.options.DataTermFcn))  ...
        ' pairwise term functions and ' num2str(numel(L.options.PairWiseTermFactors)) ...
        ' but both must be the same']);
end

valid_foo = {@neighbour_distance_term_icm, @zero_pairwise_score_icm};

for i=1:numel(L.options.PairWiseTermFcn)
    
    if ~isequalFncCell(L.options.PairWiseTermFcn{i}, valid_foo)
        error(['Unkown ICM PairWiseTermFcn @' func2str(L.options.PairWiseTermFcn{i}) ...
            ' in ' L.args_path]);
    end
    
end

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
    else
        foo_str = func2str(L.options.OutputFcn{i});
        error(['Unkown outputFnc ' foo_str ' in do_icm_solve']);
    end
end

%% Return the full options struct
options_out = L.options;

end

