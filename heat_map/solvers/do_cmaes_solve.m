function [ heat_map_v, best_error, exitflag] = do_cmaes_solve( ...
    init_heat_map, fitness_foo, paths_str, summary_data, goal_img, ...
    goal_mask, opts, maya_send)
%DO_CMAES_SOLVE CMAES solver for heat map reconstruction


%% Options
exitflag = -1;
% Path where the initial population will be saved
output_data_path = [paths_str.output_folder 'OutputData.mat'];

options = get_icm_options_from_file( opts, init_heat_map,  ...
    goal_img, goal_mask, output_data_path, paths_str, true, fitness_foo, ...
    maya_send);

LB = ones(init_heat_map.count, 1) * opts.LB;
UB = ones(init_heat_map.count, 1) * opts.UB;

% Initial guess for gradient solver, is a row vector
InitialPopulation = opts.initGuessFnc(init_heat_map, LB', UB');

% Save the initial value
save(output_data_path, 'InitialPopulation');

options.LBounds = LB;
options.UBounds = UB;

% The solution should be in the range of x0 +- 2 * sigma_0
% according to the cmaes documentation
sigma_0 = mean([opts.LB, opts.UB]) / 2;

%% Call the CMAES solver
startTime = tic;

% TODO A C++ newer and faster implementation is provided in the link below,
% adding it as a mex file shouldn't be too dificult
% https://github.com/beniz/libcmaes

[heat_map_v, best_error, counteval, message, ~, ~, countiter] = ...
    cmaes(fitness_foo, InitialPopulation, sigma_0, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% CMAES never calls output function with done, do it here
% do it manually here
optimValues = struct('funccount', counteval, 'iteration', countiter, ...
    'fval', best_error, 'procedure', message{1});

for i=1:numel(opts.options.OutputFcn)
    % Call the anonymous versions which already include the inputs
    options.OutputFcn{i}(heat_map_v, optimValues, 'done');
end

%% Transpose
% Cmaes solver uses column order, switch to row order for
% consistency with the other solvers
heat_map_v = heat_map_v';

%% Save data to file
FinalScores = best_error;
FinalPopulation = heat_map_v;
save(output_data_path, 'FinalPopulation', 'FinalScores', '-append');

%% Visualize distance space
%visualize_score_space(output_data_path, paths_str.visualization_fig_path);

%% Save summary file
summary_data.OptimizationMethod = 'CMAES';
summary_data.ImageError = best_error;
summary_data.HeatMapSize = init_heat_map.size;
summary_data.HeatMapNumVariables = init_heat_map.count;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
summary_data.InitGuessFile = init_heat_map.filename;
summary_data.OuputDataFile = output_data_path;
summary_data.sigma_0 = sigma_0;

summary_data.options = options;

save_summary_file(paths_str.summary, summary_data, []);

exitflag = 0;

end

