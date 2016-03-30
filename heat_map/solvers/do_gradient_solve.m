function [ heat_map_v, best_error, exitflag] = do_gradient_solve( ...
    max_ite, time_limit, LB, UB,  init_heat_map, fitness_foo, paths_str, ...
    summary_data)
% Gradient descent solver for heat map reconstruction
%% Options for the gradient descent solver
% Get default values
options = optimoptions(@fmincon);

% N.B. If the gradient function is not provided, the algorithm will
% evaluate the function for every dimension, e.g. 32768 times for a small
% 32x32x32 volume, before even starting the optimization, checking for max
% iterations, max funEvals or calling OutputFnc
options.MaxIter = max_ite;
options.MaxFunEvals = max_ite;
options.Display = 'iter-detailed'; % Give some output on each iteration

startTime = tic;
options.OutputFcn = @(x, optimValues, state) gradient_time_limit(x, ...
    optimValues, state, time_limit, startTime);

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
summary_data.LowerBounds = LB(1);
summary_data.UpperBounds = UB(1);
summary_data.InitGuessFile = init_heat_map.filename;

% For gradient, options is a class, convert it to struct to use it in the
% save summary function, the struct() function also copies the private data
% so copy the public one manually
fields = fieldnames(options);
for i=1:numel(fields)
    opt_struct.(fields{i}) = options.(fields{i});
end

save_summary_file(paths_str.summary, summary_data, opt_struct);

end

