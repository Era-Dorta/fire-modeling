function [ heat_map_v, best_error, exitflag] = do_genetic_solve( ...
    max_ite, time_limit, LB, UB, heat_map_size, fitness_foo, paths_str)
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


LB = ones(heat_map_size, 1) * LB;
UB = ones(heat_map_size, 1) * UB;

% Rows are number of individuals, and columns are the dimensions
options.InitialPopulation = getRandomInitPopulation( LB', UB', options.PopulationSize );

A = [];
b = [];
Aeq = [];
beq = [];
nonlcon = [];

%% Call the genetic algorithm optimization

[heat_map_v, best_error, exitflag] = ga(fitness_foo, heat_map_size, ...
    A, b, Aeq, beq, LB, UB, nonlcon, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% Save summary file
save_summary_file(paths_str.summary, 'Genetic Algorithms', best_error, ...
    heat_map_size, options, LB(1), UB(1), totalTime);
end

