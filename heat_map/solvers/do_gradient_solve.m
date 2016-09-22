function [ heat_map_v, best_error, exitflag] = do_gradient_solve( ...
    init_heat_map, fitness_foo, paths_str, summary_data, goal_img, ...
    goal_mask, opts, maya_send)
% Gradient descent solver for heat map reconstruction
%% Options for the gradient descent solver
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

if options.UseParallel
    warning('fminsearch in parallel to be implemented');
    % TODO Do the search using one of this methods, those methods only
    % support fmincon, fminunc, lsqnonlin, lsqcurvefit
    % http://uk.mathworks.com/help/gads/multistart-class.html
    % http://uk.mathworks.com/help/gads/globalsearch-class.html
end

%% Call the gradient descent optimization
startTime = tic;

[heat_map_v, best_error, exitflag] = fminsearch(fitness_foo, ...
    InitialPopulation, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% If grad_time_limit made it stop, @gradsavescores was not called, so we
% do it manually here
if exitflag == -1 % Fail by output function
    for i=1:numel(opts.options.OutputFcn) % Check for gradsavescores
        if isequal(opts.options.OutputFcn{i}, @gradsavescores)
            % Call the anonymous version which already includes the save path
            options.OutputFcn{i}([], [], 'done');
            break;
        end
    end
end

%% Save data to file
FinalScores = best_error;
FinalPopulation = heat_map_v;
save(output_data_path, 'FinalPopulation', 'FinalScores', '-append');

%% Visualize distance space
visualize_score_space(output_data_path, paths_str.visualization_fig_path);

%% Save summary file

summary_data.OptimizationMethod = 'Gradient descent';
summary_data.ImageError = best_error;
summary_data.HeatMapSize = init_heat_map.size;
summary_data.HeatMapNumVariables = init_heat_map.count;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
summary_data.InitGuessFile = init_heat_map.filename;
summary_data.OuputDataFile = output_data_path;

% For gradient, options is a class, convert it to struct to use it in the
% save summary function, the struct() function also copies the private data
% so copy the public one manually
fields = fieldnames(summary_data.options);
for i=1:numel(fields)
    opt_struct.(fields{i}) = summary_data.options.(fields{i});
end
summary_data.options = opt_struct;

save_summary_file(paths_str.summary, summary_data, []);

end

