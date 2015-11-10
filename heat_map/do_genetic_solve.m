function [ heat_map_v, best_error, exitflag] = do_genetic_solve( ...
    max_ite, time_limit, LB, UB, init_heat_map,  fitness_foo)
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

LB = ones(1, init_heat_map.size) * LB;
UB = ones(1, init_heat_map.size) * UB;

A = [];
b = [];
Aeq = [];
beq = [];
nonlcon = [];

%% Call the genetic algorithm optimization
[heat_map_v, best_error, exitflag] = ga(fitness_foo, init_heat_map.size, ...
    A, b, Aeq, beq, LB, UB, nonlcon, options);
end

