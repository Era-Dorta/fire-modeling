function [ heat_map_v, best_error, exitflag] = do_genetic_solve( ...
    max_ite, time_limit, LB, UB, init_heat_map, fitness_foo, paths_str, ...
    summary_data)
% Genetics Algorithm solver for heat map reconstruction
%% Options for the ga
% Get default values
options = gaoptimset(@ga);
options.PopulationSize = 30;
options.Generations = max(fix(max_ite / options.PopulationSize), 1);
options.TimeLimit = time_limit;
options.EliteCount = 1;
options.Display = 'iter'; % Give some output on each iteration
options.MutationFcn = @mutationadaptfeasible;

% Path where the initial population will be saved
init_population_path = [paths_str.output_folder 'InitialPopulation.mat'];

% Random initial population
options.CreationFcn = @(x, y, z)gacreationrandom(x , y, z, init_population_path);

% Linearly spaced population, giving an extra path argument makes the
% creation function save the population in a file
% options.CreationFcn = @(x, y, z)gacreationlinspace(x , y, z, ...
%     init_population_path);

% Function executed on each iteration, there is a PlotFcns too, but it
% creates a figure outside of our control and it makes the plotting and
% saving too dificult
plotf = @(options,state,flag)gaplotbestcustom(options, state, flag, paths_str.errorfig);

% Matlab is using cputime to measure time limits in GA and Simulated
% Annealing solvers, which just doesn't work with multiple cores and
% multithreading even if the value is scaled with the number of cores.
% Add a custom function to do the time limit check
startTime = tic;
timef = @(options, state, flag)ga_time_limit( options, state, flag, startTime);

options.OutputFcns = {plotf, timef};

% Our only constrains are upper and lower bounds
A = [];
b = [];
Aeq = [];
beq = [];
nonlcon = [];
LB = ones(init_heat_map.count, 1) * LB;
UB = ones(init_heat_map.count, 1) * UB;

disp(['Population size ' num2str(options.PopulationSize) ', number of '...
    'variables ' num2str(init_heat_map.count)]);

%% Call the genetic algorithm optimization

[heat_map_v, best_error, exitflag] = ga(fitness_foo, init_heat_map.count, ...
    A, b, Aeq, beq, LB, UB, nonlcon, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% Save summary file
% In the summary file just say were the init population file was saved
options.InitialPopulation = init_population_path;

summary_data.OptimizationMethod = 'Genetic Algorithms';
summary_data.ImageError = best_error;
summary_data.HeatMapSize = init_heat_map.size;
summary_data.HeatMapNumVariables = init_heat_map.count;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
summary_data.LowerBounds = LB(1);
summary_data.UpperBounds = UB(1);

save_summary_file(paths_str.summary, summary_data, options);
end

