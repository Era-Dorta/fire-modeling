function [ heat_map_v, best_error, exitflag] = do_permute_ga_solve( ...
    init_heat_map, fitnessFnc, paths_str, summary_data, goal_img, ...
    goal_mask, opts)
%DO_PERMUTE_GA_SOLVE solver for heat map reconstruction
% Simple permutation based solver, use a gacreation function to create an
% initial population, on each iteratio permute the voxels of the current
% individual and keep the permutation if it is better than the previous one

%% Options preprocessing
% Path where the initial population will be saved
output_data_path = [paths_str.output_folder 'OutputData.mat'];

options = get_ga_options_from_file( opts, init_heat_map,  ...
    goal_img, goal_mask, output_data_path, paths_str, false);

options.LinearConstr.lb = ones(init_heat_map.count, 1) * opts.LB;
options.LinearConstr.ub = ones(init_heat_map.count, 1) * opts.UB;
options.PopInitRange = [options.LinearConstr.lb'; options.LinearConstr.ub'];

prev_size = options.PopulationSize;
options.PopulationSize = 1;

GenomeLength = init_heat_map.count;

%% Population initialization
heat_map_v = options.CreationFcn( GenomeLength, [], options);

fitnessFnc = @(x) fitnessFnc(x, heat_map_v);

options.PopulationSize = prev_size;

% Our only constrains are upper and lower bounds
A = [];
b = [];
Aeq = [];
beq = [];
nonlcon = [];
% Use this one to avoid repetitions in the indices
% nonlcon = @(x) nonlcon_fitness_order(x, init_heat_map.count);
IntCon = 1:init_heat_map.count; % All variables are integers
LB = ones(1, init_heat_map.count);
UB = zeros(1, init_heat_map.count) + init_heat_map.count;

disp(['Population size ' num2str(options.PopulationSize) ', number of '...
    'variables ' num2str(init_heat_map.count)]);

%% Call the genetic algorithm optimization
startTime = tic;

[heat_map_idx, best_error, exitflag, ~, FinalPopulation, FinalScores] = ...
    ga(fitnessFnc, init_heat_map.count, A, b, Aeq, beq, LB, UB, nonlcon, ...
    IntCon, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

% Get the final heat map using the indices
heat_map_v = heat_map_v(heat_map_idx);

%% Save data to file
save(output_data_path, 'FinalPopulation', 'FinalScores', '-append');

%% Visualize distance space
visualize_score_space(output_data_path, paths_str.visualization_fig_path);

%% Save summary file
% In the summary file just say were the init population file was saved
summary_data.OptimizationMethod = 'GA for permutations';
summary_data.ImageError = best_error;
summary_data.HeatMapSize = init_heat_map.size;
summary_data.HeatMapNumVariables = init_heat_map.count;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
summary_data.OuputDataFile = output_data_path;
summary_data.options.InitialPopulation = output_data_path;

save_summary_file(paths_str.summary, summary_data, []);

end

