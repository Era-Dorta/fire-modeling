function [ heat_map_v, best_error, exitflag] = do_simulanneal_solve( ...
    max_ite, time_limit, LB, UB,  init_heat_map, fitness_foo, summary_file)
% Simulated Annealing solver for heat map reconstruction
%% Options for the SA
% Get default values
options = saoptimset('simulannealbnd');
options.MaxIter = max_ite;
options.TimeLimit = time_limit;
options.InitialTemperature = (UB - LB) / 6;
options.Display = 'iter'; % Give some output on each iteration

LB = ones(init_heat_map.size, 1) * LB;
UB = ones(init_heat_map.size, 1) * UB;

%% Call the genetic algorithm optimization
% Use initial_heat_map as first guess
startTime = tic;

[heat_map_v, best_error, exitflag] = simulannealbnd(fitness_foo, ...
    init_heat_map.v', LB, UB, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% Save summary file
save_summary_file(summary_file, 'Simulated Annealing', best_error, ...
    init_heat_map.size, options, LB(1), UB(1), totalTime, init_heat_map.filename);
end
