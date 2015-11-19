function [ heat_map_v, best_error, exitflag] = do_gradient_solve( ...
    max_ite, time_limit, LB, UB,  init_heat_map, fitness_foo, summary_file)
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
options.OutputFcn = @(x, optimValues, state) gradient_time_limit(x, optimValues, state, time_limit);

LB = ones(init_heat_map.count, 1) * LB;
UB = ones(init_heat_map.count, 1) * UB;

A = [];
b = [];
Aeq = [];
beq = [];
nonlcon = [];

% Initial guess for SA, is a row vector
% init_guess = init_heat_map.v';
init_guess = getRandomInitPopulation( LB', UB', 1);

%% Call the gradient descent optimization

startTime = tic;

[heat_map_v, best_error, exitflag] = fmincon(fitness_foo, init_guess, ...
    A, b, Aeq, beq, LB, UB, nonlcon, options);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% Save summary file
save_summary_file(summary_file, 'Gradient descent', best_error, ...
    init_heat_map.count, options, LB(1), UB(1), totalTime, init_heat_map.filename);
end

