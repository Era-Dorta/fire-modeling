function [ heat_map_v, best_error, exitflag] = do_simulanneal_solve( ...
    init_heat_map, fitness_foo, paths_str, summary_data, L)
% Simulated Annealing solver for heat map reconstruction
%% Options for the SA

options = L.options;

options.InitialTemperature = options.InitialTemperature * (L.UB - L.LB);

% Matlab is using cputime to measure time limits in GA and Simulated
% Annealing solvers, which just doesn't work with multiple cores and
% multithreading even if the value is scaled with the number of cores.
% Add a custom function to do the time limit check
if isequal(options.OutputFcns, @sa_time_limit)
    startTime = tic;
    options.OutputFcns = @(options, state, flag)sa_time_limit( options, ...
        state, flag, startTime);
else
    error('Unkown outputFnc in do_simulanneal_solve');
end

LB = ones(init_heat_map.count, 1) * L.LB;
UB = ones(init_heat_map.count, 1) * L.UB;

% Initial guess for SA, is a row vector
% init_guess = init_heat_map.v';
InitialPopulation = getRandomInitPopulation( LB', UB', 1);

% Path where the initial population will be saved
init_population_path = [paths_str.output_folder 'InitialPopulation.mat'];
save(init_population_path, 'InitialPopulation');

%% Call the simulated annealing optimization
% Use initial_heat_map as first guess

[heat_map_v, best_error, exitflag] = simulannealbnd(fitness_foo, ...
    InitialPopulation, LB, UB, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% Save summary file
summary_data.OptimizationMethod = 'Simulated Annealing';
summary_data.ImageError = best_error;
summary_data.HeatMapSize = init_heat_map.size;
summary_data.HeatMapNumVariables = init_heat_map.count;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
summary_data.InitGuessFile = init_heat_map.filename;
summary_data.InitialTemperature = options.InitialTemperature;

save_summary_file(paths_str.summary, summary_data, []);
end

