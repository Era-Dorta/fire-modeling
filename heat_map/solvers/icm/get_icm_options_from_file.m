function [ options_out ] = get_icm_options_from_file( L, init_heat_map,  ...
    goal_img, goal_mask, output_data_path, paths_str, use_first)
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
    error(['Unkown GA CrossoverFcn @' func2str(L.options.CreateSamplesFcn) ...
        ' in ' L.args_path]);
end

%% UpdateSampleRangeFcn
if isequal(L.options.UpdateSampleRangeFcn, @linear_range_reduce_temperature_icm)
    
    
elseif ~isequal(L.options.CreationFcn, @gacreationuniform) && ...
        ~isequal(L.options.CreationFcn, @gacreationlinearfeasible)
    
    error(['Unkown ICM CreateSamplesFcn @' func2str(L.options.CreationFcn) ...
        ' in ' L.args_path]);
    
end

%% DataTermFcn
if isequal(L.options.DataTermFcn, @data_term_score)
    
    
else
    
    valid_foo = { };
    
    if ~isequalFncCell(L.options.DataTermFcn, valid_foo)
        error(['Unkown ICM DataTermFcn @' func2str(L.options.DataTermFcn) ...
            ' in ' L.args_path]);
    end
    
end

%% PairWiseTermFcn
if isequal(L.options.PairWiseTermFcn, @pairwise_term)
    
    
else
    
    valid_foo = { };
    
    if ~isequalFncCell(L.options.PairWiseTermFcn, valid_foo)
        error(['Unkown ICM PairWiseTermFcn @' func2str(L.options.PairWiseTermFcn) ...
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

