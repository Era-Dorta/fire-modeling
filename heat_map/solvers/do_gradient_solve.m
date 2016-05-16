function [ heat_map_v, best_error, exitflag] = do_gradient_solve( ...
    LB, UB,  init_heat_map, fitness_foo, paths_str, ...
    summary_data, goal_img, args_path)
% Gradient descent solver for heat map reconstruction
%% Options for the gradient descent solver
num_goal = numel(goal_img);

L = load(args_path);
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
    else
        error('Unkown outputFnc in do_gradient_solve');
    end
end

LB = ones(init_heat_map.count, 1) * LB;
UB = ones(init_heat_map.count, 1) * UB;

A = [];
b = [];
Aeq = [];
beq = [];
nonlcon = [];

% Initial guess for SA, is a row vector
% init_guess = init_heat_map.v';
InitialPopulation = getRandomInitPopulation( LB', UB', 1);

% Path where the initial population will be saved
init_population_path = [paths_str.output_folder 'InitialPopulation.mat'];
save(init_population_path, 'InitialPopulation');

%% Call the gradient descent optimization

[heat_map_v, best_error, exitflag] = fmincon(fitness_foo, InitialPopulation, ...
    A, b, Aeq, beq, LB, UB, nonlcon, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% Save summary file

summary_data.OptimizationMethod = 'Gradient descent';
summary_data.ImageError = best_error;
summary_data.HeatMapSize = init_heat_map.size;
summary_data.HeatMapNumVariables = init_heat_map.count;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
summary_data.InitGuessFile = init_heat_map.filename;

% For gradient, options is a class, convert it to struct to use it in the
% save summary function, the struct() function also copies the private data
% so copy the public one manually
fields = fieldnames(L.options);
for i=1:numel(fields)
    opt_struct.(fields{i}) = L.options.(fields{i});
end
L.options = opt_struct;

save_summary_file(paths_str.summary, summary_data, L);

end

