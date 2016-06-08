function [ heat_map_v, best_error, exitflag] = do_permute_ga_float_solve( ...
    init_heat_map, fitnessFnc, paths_str, summary_data, goal_img, ...
    goal_mask, opts)
%DO_PERMUTE_GA_FLOAT_SOLVE solver for heat map reconstruction
% Simple permutation based solver, use a gacreation function to create an
% initial population, on each iteratio permute the voxels of the current
% individual and keep the permutation if it is better than the previous one

%% Options for the ga

% Path where the initial population will be saved
output_data_path = [paths_str.output_folder 'OutputData.mat'];

prev_creation = opts.options.CreationFcn;
opts.options.CreationFcn = opts.initCreationFnc;

options = get_ga_options_from_file( opts, init_heat_map,  ...
    goal_img, goal_mask, output_data_path, paths_str, false);

options.LinearConstr.lb = ones(init_heat_map.count, 1) * opts.LB;
options.LinearConstr.ub = ones(init_heat_map.count, 1) * opts.UB;
options.PopInitRange = [options.LinearConstr.lb'; options.LinearConstr.ub'];
options.PopulationSize = 1;

GenomeLength = init_heat_map.count;

%% Population initialization
initHeatMap = options.CreationFcn( GenomeLength, [], options);
fitnessFnc = @(x) fitnessFnc(x, initHeatMap);

opts.options.CreationFcn = prev_creation;

options = get_ga_options_from_file( opts, init_heat_map,  ...
    goal_img, goal_mask, output_data_path, paths_str, false);

% Our only constrains are upper and lower bounds
A = [];
b = [];
Aeq = [];
beq = [];
nonlcon = [];
LB = [];
UB = [];

disp(['Population size ' num2str(options.PopulationSize) ', number of '...
    'variables ' num2str(init_heat_map.count)]);

%% Call the genetic algorithm optimization
startTime = tic;

[heat_map_idx, best_error, exitflag, output, FinalPopulation, FinalScores] = ...
    ga(fitnessFnc, init_heat_map.count, A, b, Aeq, beq, LB, UB, nonlcon, ...
    options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

% Decode the GA data into a heatmap
heat_map_v = decode_permute_ga_solve( heat_map_idx, initHeatMap );

%% Save data to file
FinalPopulation = decode_permute_ga_solve( FinalPopulation, initHeatMap );
out_data = load(output_data_path);
AllPopulation = decode_permute_ga_solve( out_data.AllPopulation, initHeatMap );
InitialPopulation = decode_permute_ga_solve( out_data.InitialPopulation, initHeatMap );

save(output_data_path, 'FinalPopulation', 'AllPopulation', ...
    'InitialPopulation', 'FinalScores', 'initHeatMap', '-append');

%% Visualize distance space
visualize_score_space(output_data_path, paths_str.visualization_fig_path);

%% Save summary file
% In the summary file just say were the init population file was saved
summary_data.OptimizationMethod = 'Permutations GA Float';
summary_data.ImageError = best_error;
summary_data.HeatMapSize = init_heat_map.size;
summary_data.HeatMapNumVariables = init_heat_map.count;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
summary_data.OuputDataFile = output_data_path;
summary_data.options.InitialPopulation = output_data_path;

save_summary_file(paths_str.summary, summary_data, []);

end

