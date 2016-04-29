function [ options_out ] = get_ga_options_from_file( args_path, init_heat_map,  ...
    goal_img, goal_mask, init_population_path, paths_str, is_ga_re)
%GET_GA_OPTIONS_FROM_FILE Sets GA options
%   [ OPTIONS_OUT ] = GET_GA_OPTIONS_FROM_FILE( ARGS_PATH, INIT_HEAT_MAP,
%      GOAL_IMG, GOAL_MASK, INIT_POPULATION_PATH, PATHS_STR) Given a mat
%   file path in ARGS_PATH, and the rest of arguments. Outputs a valid
%   gaoptimiset instance in OPTIONS_OUT
%
%   See also do_genetic_solve, do_genetic_solve_resample, args_test1,
%   args_test_template

L = load(args_path);

num_goal = numel(goal_img);

if is_ga_re % GA resampling has custom options for the first iteration
    L.options.CreationFcn = L.CreationFcnFirst;
    L.options.CrossoverFcn = L.CrossoverFcnFirst;
    L.options.MutationFcn = L.MutationFcnFirst;
end

%% Creation function
if isequal(L.options.CreationFcn, @gacreationheuristic1)
    
    L.options.CreationFcn = @( GenomeLength, FitnessFcn, options) gacreationheuristic1 ...
        (GenomeLength, FitnessFcn, options, init_heat_map, goal_img, ...
        goal_mask, init_population_path);
    
elseif isequal(L.options.CreationFcn, @gacreationrandom)
    
    L.options.CreationFcn = @(x, y, z)gacreationrandom(x , y, z, init_population_path);
    
elseif isequal(L.options.CreationFcn, @gacreationfrominitguess)
    
    % Initial population from a user provide guess
    L.options.CreationFcn = @( GenomeLength, FitnessFcn, options) gacreationfrominitguess ...
        ( GenomeLength, FitnessFcn, options, init_heat_map, L.creation_fnc_mean, ...
        L.creation_fnc_sigma, init_population_path );
    
elseif isequal(L.options.CreationFcn, @gacreationlinspace)
    
    % Linearly spaced population
    L.options.CreationFcn = @(x, y, z)gacreationlinspace(x , y, z, ...
        init_population_path);
    
elseif ~isequal(L.options.CreationFcn, @gacreationuniform) && ...
        ~isequal(L.options.CreationFcn, @gacreationlinearfeasible)
    
    error(['Unkown GA CreationFcn in ' args_path]);
    
end

%% Crossover function
if isequal(L.options.CrossoverFcn, @gaxoverpriorhisto)
    
    L.options.CrossoverFcn = @(parents, options, GenomeLength, FitnessFcn, ...
        unused, thisPopulation) gaxoverpriorhisto (parents, options, ...
        GenomeLength, FitnessFcn, unused, thisPopulation, init_heat_map.xyz, ...
        init_heat_map.size, min(init_heat_map.xyz), max(init_heat_map.xyz), ...
        goal_img, goal_mask);
    
elseif isequal(L.options.CrossoverFcn, @gacrossovercombineprior)
    
    L.options.CrossoverFcn = @(parents, options, GenomeLength, FitnessFcn, ...
        unused, thisPopulation) gacrossovercombineprior (parents, options, ...
        GenomeLength, FitnessFcn, unused, thisPopulation, init_heat_map.xyz, ...
        init_heat_map.size, min(init_heat_map.xyz), max(init_heat_map.xyz));
    
elseif isequal(L.options.CrossoverFcn, @gacrossovercombine)
    
    L.options.CrossoverFcn = @(parents, options, GenomeLength, FitnessFcn, ...
        unused, thisPopulation) gacrossovercombine (parents, options, ...
        GenomeLength, FitnessFcn, unused, thisPopulation, init_heat_map.xyz, ...
        min(init_heat_map.xyz), max(init_heat_map.xyz));
    
else
    valid_foo = { @crossoverscattered ,@crossoversinglepoint, ...
        @crossovertwopoint ,@crossoverintermediate, @crossoverheuristic };
    
    is_valid = false;
    for i=1:numel(valid_foo)
        if isequal(L.options.CrossoverFcn, valid_foo{i})
            is_valid = true;
            break;
        end
    end
    
    if ~is_valid
        error(['Unkown GA CrossoverFcn in ' args_path]);
    end
end

%% Mutation function
if isequal(L.options.MutationFcn, @gamutationadaptprior)
    
    L.options.MutationFcn = @(parents, options, GenomeLength, FitnessFcn,  ...
        state, thisScore, thisPopulation) gamutationadaptprior (parents, options, ...
        GenomeLength, FitnessFcn, state, thisScore, thisPopulation, ...
        init_heat_map.xyz, init_heat_map.size);
    
else
    
    valid_foo = { @mutationadaptfeasible, @gamutationnone, ...
        @gamutationadaptscale, @gamutationmean, @crossoverheuristic, ...
        @mutationgaussian, @mutationuniform, @mutationadaptfeasible};
    
    is_valid = false;
    for i=1:numel(valid_foo)
        if isequal(L.options.MutationFcn, valid_foo{i})
            is_valid = true;
            break;
        end
    end
    
    if ~is_valid
        error(['Unkown GA MutationFcn in ' args_path]);
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
        
    else
        error(['Unkown GA OutputFcn in ' args_path]);
    end
end

%% Return the full options struct
options_out = L.options;

end

