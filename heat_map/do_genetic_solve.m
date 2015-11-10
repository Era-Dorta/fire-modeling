function [ heat_map_v, best_error, exitflag] = do_genetic_solve( ...
    max_ite, time_limit, LB, UB, heat_map_size, fitness_foo, summary_file)
% Genetics Algorithm solver for heat map reconstruction
%% Options for the ga
% Get default values
options = gaoptimset(@ga);
options.Generations = max_ite;
options.TimeLimit = time_limit;
options.PopulationSize = 10;
options.EliteCount = 1;
options.Display = 'iter'; % Give some output on each iteration
options.MutationFcn = @mutationadaptfeasible;

LB = ones(heat_map_size, 1) * LB;
UB = ones(heat_map_size, 1) * UB;

A = [];
b = [];
Aeq = [];
beq = [];
nonlcon = [];

%% Call the genetic algorithm optimization
tic;
[heat_map_v, best_error, exitflag] = ga(fitness_foo, heat_map_size, ...
    A, b, Aeq, beq, LB, UB, nonlcon, options);

%% Save summary file
save_summary_file(summary_file, 'Genetic Algorithms', best_error, ...
    heat_map_size, options, LB(1), UB(1), toc);
end

