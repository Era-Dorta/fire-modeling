function [ heat_map_v, best_error, exitflag] = do_genetic_solve( LB, UB, ...
    init_heat_map, fitness_foo, paths_str, summary_data, goal_img, ...
    goal_mask, args_path)
% Genetics Algorithm solver for heat map reconstruction
%% Options for the ga

% Path where the initial population will be saved
init_population_path = [paths_str.output_folder 'InitialPopulation.mat'];

options = get_ga_options_from_file( args_path, init_heat_map,  ...
    goal_img, goal_mask, init_population_path, paths_str, LB, UB, false);

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
startTime = tic;

[heat_map_v, best_error, exitflag] = ga(fitness_foo, init_heat_map.count, ...
    A, b, Aeq, beq, LB, UB, nonlcon, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% Save summary file
% In the summary file just say were the init population file was saved
extra_data = load(args_path);
extra_data.options.InitialPopulation = init_population_path;

summary_data.OptimizationMethod = 'Genetic Algorithms';
summary_data.ImageError = best_error;
summary_data.HeatMapSize = init_heat_map.size;
summary_data.HeatMapNumVariables = init_heat_map.count;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];

save_summary_file(paths_str.summary, summary_data, extra_data);
end

