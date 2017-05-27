function [ cam_attr, best_error, exitflag] = do_gradient_solve_cam( ...
    init_cam_attr, fitness_foo, paths_str, summary_data, goal_img, ...
    goal_mask, opts, maya_send)
% Gradient descent solver for heat map reconstruction
%% Options for the gradient descent solver
% Path where the initial population will be saved
output_data_path = [paths_str.output_folder 'OutputData.mat'];

options = get_icm_options_from_file( opts, init_cam_attr,  ...
    goal_img, goal_mask, output_data_path, paths_str, true, fitness_foo, ...
    maya_send);

LB = opts.LB;
UB = opts.UB;

% Initial guess for gradient solver, is a row vector
InitialPopulation = init_cam_attr;

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

[cam_attr, best_error, exitflag, output] = fminsearch(fitness_foo, ...
    InitialPopulation, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% If grad_time_limit made it stop, call the functions to perform the save
% do it manually here
if exitflag == -1 % Fail by output function
    optimValues = struct('funccount', output.funcCount, 'iteration', output.iterations, ...
        'fval', best_error, 'procedure', output.message);
    
    for i=1:numel(opts.options.OutputFcn)
        % Call the anonymous versions which already include the inputs
        options.OutputFcn{i}(cam_attr, optimValues, 'done');
    end
end

%% Save data to file
FinalScores = best_error;
FinalPopulation = cam_attr;
save(output_data_path, 'FinalPopulation', 'FinalScores', '-append');

%% Visualize distance space
visualize_score_space(output_data_path, paths_str.visualization_fig_path);

%% Save summary file

summary_data.OptimizationMethod = 'Gradient descent';
summary_data.ImageError = best_error;
summary_data.HeatMapSize = init_cam_attr.size;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
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

