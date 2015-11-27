function [ heat_map_v, best_error, exitflag] = do_simulanneal_solve( ...
    max_ite, time_limit, LB, UB,  init_heat_map, fitness_foo, summary_file, ...
    summary_data)
% Simulated Annealing solver for heat map reconstruction
%% Options for the SA
% Get default values
options = saoptimset('simulannealbnd');
options.MaxIter = max_ite;
options.MaxFunEvals = max_ite;
options.TimeLimit = time_limit;
options.InitialTemperature = (UB - LB) / 6;
options.Display = 'iter'; % Give some output on each iteration

% Matlab is using cputime to measure time limits in GA and Simulated
% Annealing solvers, which just doesn't work with multiple cores and
% multithreading even if the value is scaled with the number of cores.
% Add a custom function to do the time limit check
startTime = tic;
timef = @(options, state, flag)sa_time_limit( options, state, flag, startTime);

options.OutputFcns = timef;

LB = ones(init_heat_map.count, 1) * LB;
UB = ones(init_heat_map.count, 1) * UB;

% Initial guess for SA, is a row vector
% init_guess = init_heat_map.v';
init_guess = getRandomInitPopulation( LB', UB', 1);

%% Call the simulated annealing optimization
% Use initial_heat_map as first guess

[heat_map_v, best_error, exitflag] = simulannealbnd(fitness_foo, ...
    init_guess, LB, UB, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% Save summary file

summary_data.OptimizationMethod = 'Simulated Annealing';
summary_data.ImageError = best_error;
summary_data.HeatMapSize = init_heat_map.size;
summary_data.HeatMapNumVariables = init_heat_map.count;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
summary_data.LowerBounds = LB(1);
summary_data.UpperBounds = UB(1);
summary_data.InitGuessFile = init_heat_map.filename;

save_summary_file(summary_file, summary_data, options);
end

