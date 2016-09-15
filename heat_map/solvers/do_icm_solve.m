function [ heat_map_v, best_error, exitflag] = do_icm_solve( ...
    init_heat_map, fitness_foo, paths_str, summary_data, goal_img, L)
% Gradient descent solver for heat map reconstruction
%% Options for the gradient descent solver
num_goal = numel(goal_img);

% Path where the initial population will be saved
output_data_path = [paths_str.output_folder 'OutputData.mat'];

options = L.options;

for i=1:numel(options.OutputFcn)
    if isequal(options.OutputFcn{i}, @gradient_time_limit)
        startTime = tic;
        options.OutputFcn{i} = @(x, optimValues, state) gradient_time_limit(x, ...
            optimValues, state, L.time_limit, startTime);
    elseif isequal(options.OutputFcn{i}, @gradplotbestgen)
        options.OutputFcn{i} = @(x, optimValues, state) gradplotbestgen(x, ...
            optimValues, state, paths_str.ite_img, paths_str.output_folder, ...
            num_goal);
    elseif isequal(options.OutputFcn{i}, @gradsavescores)
        options.OutputFcn{i} = @(x, optimValues, state) gradsavescores(x, ...
            optimValues, state, output_data_path);
    else
        foo_str = func2str(options.OutputFcn{i});
        error(['Unkown outputFnc ' foo_str ' in do_icm_solve']);
    end
end

LB = ones(init_heat_map.count, 1) * L.LB;
UB = ones(init_heat_map.count, 1) * L.UB;

% Initial guess for SA, is a row vector
% init_guess = init_heat_map.v';
InitialPopulation = getRandomInitPopulation( LB', UB', 1);

% Save the initial value
save(output_data_path, 'InitialPopulation');

%% Call the gradient descent optimization

[heat_map_v, best_error, exitflag] = icm(fitness_foo, InitialPopulation, ...
    LB, UB, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% Save data to file
FinalScores = best_error;
FinalPopulation = heat_map_v;
save(output_data_path, 'FinalPopulation', 'FinalScores', '-append');

%% Visualize distance space
visualize_score_space(output_data_path, paths_str.visualization_fig_path);

%% Save summary file

summary_data.OptimizationMethod = 'ICM';
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

