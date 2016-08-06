function [ options_out ] = get_ga_options_from_file( L, init_heat_map,  ...
    goal_img, goal_mask, output_data_path, paths_str, use_first)
%GET_GA_OPTIONS_FROM_FILE Sets GA options
%   [ OPTIONS_OUT ] = GET_GA_OPTIONS_FROM_FILE( ARGS_PATH, INIT_HEAT_MAP,
%      GOAL_IMG, GOAL_MASK, INIT_POPULATION_PATH, PATHS_STR) Given a mat
%   file path in ARGS_PATH, and the rest of arguments. Outputs a valid
%   gaoptimiset instance in OPTIONS_OUT
%
%   See also do_genetic_solve, do_genetic_solve_resample, args_test1,
%   args_test_template

num_goal = numel(goal_img);

if use_first % GA resampling has custom options for the first iteration
    L.options.CreationFcn = L.CreationFcnFirst;
    L.options.CrossoverFcn = L.CrossoverFcnFirst;
    L.options.MutationFcn = L.MutationFcnFirst;
end

%% Creation function
if isequal(L.options.CreationFcn, @gacreationheuristic1)
    
    L.options.CreationFcn = @( GenomeLength, FitnessFcn, options) gacreationheuristic1 ...
        (GenomeLength, FitnessFcn, options, init_heat_map, goal_img, ...
        goal_mask, L.fuel_type, L.creation_fnc_n_bins, L.color_space, ...
        output_data_path);
    
elseif isequal(L.options.CreationFcn, @gacreationheuristic2)
    
    L.options.CreationFcn = @( GenomeLength, FitnessFcn, options) ...
        gacreationheuristic2 (GenomeLength, FitnessFcn, options,  ...
        init_heat_map, goal_img, goal_mask, L.fuel_type, L.color_space, ...
        output_data_path);
    
elseif isequal(L.options.CreationFcn, @gacreationheuristic3)
    
    L.options.CreationFcn = @( GenomeLength, FitnessFcn, options) ...
        gacreationheuristic3 (GenomeLength, FitnessFcn, options,  ...
        goal_img, goal_mask, L.fuel_type,  L.creation_fnc_n_bins, ...
        L.color_space, output_data_path);
elseif isequal(L.options.CreationFcn, @gacreationheuristic4)
    
    L.options.CreationFcn = @( GenomeLength, FitnessFcn, options) ...
        gacreationheuristic4 (GenomeLength, FitnessFcn, options,  ...
        goal_img, goal_mask, L.fuel_type,  L.creation_fnc_n_bins, ...
        L.color_space, init_heat_map.v', output_data_path);
    
elseif isequal(L.options.CreationFcn, @gacreationrandom)
    
    L.options.CreationFcn = @(x, y, z)gacreationrandom(x , y, z, output_data_path);
    
elseif isequal(L.options.CreationFcn, @gacreationfrominitguess)
    
    % Initial population from a user provide guess
    L.options.CreationFcn = @( GenomeLength, FitnessFcn, options) gacreationfrominitguess ...
        ( GenomeLength, FitnessFcn, options, init_heat_map, L.creation_fnc_mean, ...
        L.creation_fnc_sigma, output_data_path );
    
elseif isequal(L.options.CreationFcn, @gacreationlinspace)
    
    % Linearly spaced population
    L.options.CreationFcn = @(x, y, z)gacreationlinspace(x , y, z, ...
        output_data_path);
    
elseif ~isequal(L.options.CreationFcn, @gacreationuniform) && ...
        ~isequal(L.options.CreationFcn, @gacreationlinearfeasible)
    
    error(['Unkown GA CreationFcn @' func2str(L.options.CreationFcn) ...
        ' in ' L.args_path]);
    
end

%% Crossover function
if isequal(L.options.CrossoverFcn, @gacrossovercombineprior)
    
    [ prior_fncs, prior_weights, nCandidates ] = ...
        get_prior_fncs_from_file( L, init_heat_map, goal_img, ...
        goal_mask, 'crossover', true);
    
    L.options.CrossoverFcn = @(parents, options, GenomeLength, FitnessFcn, ...
        unused, thisPopulation) gacrossovercombineprior (parents, options, ...
        GenomeLength, FitnessFcn, unused, thisPopulation, init_heat_map.xyz, ...
        min(init_heat_map.xyz), max(init_heat_map.xyz), prior_fncs, ...
        prior_weights, nCandidates);
    
elseif isequal(L.options.CrossoverFcn, @gacrossovercombine)
    
    L.options.CrossoverFcn = @(parents, options, GenomeLength, FitnessFcn, ...
        unused, thisPopulation) gacrossovercombine (parents, options, ...
        GenomeLength, FitnessFcn, unused, thisPopulation, init_heat_map.xyz, ...
        min(init_heat_map.xyz), max(init_heat_map.xyz));
    
elseif isequal(L.options.CrossoverFcn, @gacrossovercombine2)
    
    L.options.CrossoverFcn = @(parents, options, GenomeLength, FitnessFcn, ...
        unused, thisPopulation) gacrossovercombine2 (parents, options, ...
        GenomeLength, FitnessFcn, unused, thisPopulation, init_heat_map.xyz, ...
        min(init_heat_map.xyz), max(init_heat_map.xyz));
    
else
    valid_foo = { @crossoverscattered ,@crossoversinglepoint, ...
        @crossovertwopoint ,@crossoverintermediate, @crossoverheuristic};
    
    if ~isequalFncCell(L.options.CrossoverFcn, valid_foo)
        error(['Unkown GA CrossoverFcn @' func2str(L.options.CrossoverFcn) ...
            ' in ' L.args_path]);
    end
end

%% Mutation function
check_size_limitations(L, init_heat_map);

if isequal(L.options.MutationFcn, @gamutationadaptprior)
    
    [ prior_fncs, prior_weights, nCandidates ] = ...
        get_prior_fncs_from_file( L, init_heat_map, goal_img, ...
        goal_mask, 'mutation', true);
    
    L.options.MutationFcn = @(parents, options, GenomeLength, FitnessFcn,  ...
        state, thisScore, thisPopulation) gamutationadaptprior (parents, options, ...
        GenomeLength, FitnessFcn, state, thisScore, thisPopulation, ...
        prior_fncs, prior_weights, nCandidates);
    
elseif isequal(L.options.MutationFcn, @gamutationscaleprior)
    
    [ prior_fncs, prior_weights, nCandidates ] = ...
        get_prior_fncs_from_file( L, init_heat_map, goal_img, ...
        goal_mask, 'mutation', true);
    
    L.options.MutationFcn = @(parents, options, GenomeLength, FitnessFcn,  ...
        state, thisScore, thisPopulation) gamutationscaleprior (parents, options, ...
        GenomeLength, FitnessFcn, state, thisScore, thisPopulation, ...
        prior_fncs, prior_weights, nCandidates, L.mut_rate);
    
elseif isequal(L.options.MutationFcn, @gamutationpermute)
    
    [ prior_fncs, prior_weights, nCandidates ] = ...
        get_prior_fncs_from_file( L, init_heat_map, goal_img, ...
        goal_mask, 'mutation', true);
    
    L.options.MutationFcn = @(parents, options, GenomeLength, FitnessFcn,  ...
        state, thisScore, thisPopulation) gamutationpermute (parents, options, ...
        GenomeLength, FitnessFcn, state, thisScore, thisPopulation, ...
        prior_fncs, prior_weights, nCandidates, L.mut_rate);
    
else
    
    valid_foo = { @mutationadaptfeasible, @gamutationnone, ...
        @gamutationadaptscale, @crossoverheuristic, ...
        @mutationgaussian, @mutationuniform, @mutationadaptfeasible};
    
    if ~isequalFncCell(L.options.MutationFcn, valid_foo)
        error(['Unkown GA MutationFcn @' func2str(L.options.MutationFcn) ...
            ' in ' L.args_path]);
    end
end

%% Output and plot functions
for i=1:numel(L.options.OutputFcns)
    if isequal(L.options.OutputFcns{i}, @gaplotbestcustom)
        
        % Function executed on each iteration, there is a PlotFcns too, but it
        % creates a figure outside of our control and it makes the plotting and
        % saving too dificult
        L.options.OutputFcns{i} = @(options,state,flag)gaplotbestcustom( ...
            options, state, flag, paths_str.errorfig);
        
    elseif isequal(L.options.OutputFcns{i}, @gaplotbestgen)
        
        % Plot the rendered image of the best heat map on each iteration
        L.options.OutputFcns{i} = @(options,state,flag)gaplotbestgen(options, ...
            state, flag, paths_str.ite_img, paths_str.output_folder, num_goal);
        
    elseif isequal(L.options.OutputFcns{i}, @ga_time_limit)
        
        % Matlab is using cputime to measure time limits in GA and Simulated
        % Annealing solvers, which just doesn't work with multiple cores and
        % multithreading even if the value is scaled with the number of cores.
        % Add a custom function to do the time limit check
        startTime = tic;
        L.options.OutputFcns{i} = @(options, state, flag)ga_time_limit( ...
            options, state, flag, startTime);
        
    elseif isequal(L.options.OutputFcns{i}, @ga_max_fnc_eval_limit)
        
        % Custom maxFunEval function, ga does not have one by default
        L.options.OutputFcns{i} = @(options, state, flag)ga_max_fnc_eval_limit( ...
            options, state, flag, L.maxFunEvals);
        
    elseif isequal(L.options.OutputFcns{i}, @gasavescores)
        
        % Save scores and best per generation in a file
        L.options.OutputFcns{i} = @(options, state, flag)gasavescores( ...
            options, state, flag, output_data_path);
    else
        error(['Unkown GA OutputFcn @' func2str(L.options.OutputFcns{i}) ...
            ' in ' L.args_path]);
    end
end

%% Return the full options struct
options_out = L.options;

end

