function [ heat_map_v, best_error, exitflag] = do_simulanneal_solve( ...
    max_ite, time_limit, LB, UB,  init_heat_map,  fitness_foo )
% Simulated Annealing solver for heat map reconstruction
%% Options for the SA
% Get default values
options = saoptimset('simulannealbnd');
options.MaxIter = max_ite;
options.TimeLimit = time_limit;
options.Display = 'iter'; % Give some output on each iteration

LB = ones(1, init_heat_map.size) * LB;
UB = ones(1, init_heat_map.size) * UB;

%% Call the genetic algorithm optimization
% Use initial_heat_map as first guess
[heat_map_v, best_error, exitflag] = simulannealbnd(fitness_foo, ...
    init_heat_map.v, LB, UB, options);
end

