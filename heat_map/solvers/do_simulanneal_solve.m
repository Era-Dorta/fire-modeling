function [ heat_map_v, best_error, exitflag] = do_simulanneal_solve( ...
    init_heat_map, fitness_foo, paths_str, summary_data, goal_img, ...
    goal_mask, opts, maya_send)
% Simulated Annealing solver for heat map reconstruction
%% Options for the SA

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

options.InitialTemperature = options.InitialTemperature * (UB - LB);

% Use gradient output functions, via a custom wrapper
options.OutputFcns = {}; % Note that for SA is OutputFcns in plural
for i=1:numel(options.OutputFcn)
    options.OutputFcns{i} = @(options_arg,optimvalues,flag) ...
        option_fn_wrapper(options_arg,optimvalues,flag, options.OutputFcn{i});
end

%% Call the simulated annealing optimization
% Use initial_heat_map as first guess
startTime = tic;

[heat_map_v, best_error, exitflag, output] = simulannealbnd(fitness_foo, ...
    InitialPopulation, LB, UB, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);


%% If sa_time_limit made it stop, call the functions to perform the save
% do it manually here
if exitflag == -1 % Fail by output function
    optimValues = struct('funccount', output.funccount, 'iteration', output.iterations, ...
        'fval', best_error, 'procedure', output.message, 'x', heat_map_v);
    
    for i=1:numel(opts.options.OutputFcns)
        % Call the anonymous versions which already include the inputs
        options.OutputFcns{i}(options, optimValues, 'done');
    end
end

%% Save data to file
FinalScores = best_error;
FinalPopulation = heat_map_v;
save(output_data_path, 'FinalPopulation', 'FinalScores', '-append');

%% Visualize distance space
visualize_score_space(output_data_path, paths_str.visualization_fig_path);

%% Save summary file

summary_data.OptimizationMethod = 'Simulated Annealing';
summary_data.ImageError = best_error;
summary_data.HeatMapSize = init_heat_map.size;
summary_data.HeatMapNumVariables = init_heat_map.count;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
summary_data.InitGuessFile = init_heat_map.filename;
summary_data.OuputDataFile = output_data_path;

summary_data.options = options;
save_summary_file(paths_str.summary, summary_data, []);

end

