function [ heat_map_v, best_error, exitflag] = do_cmaes_solve( ...
    max_ite, time_limit, LB, UB, init_heat_map, fitness_foo, paths_str, ...
    summary_data, parallel)
% CMAES solver for heat map reconstruction
%% Options for the CMAES
% Get default values
options = cmaes('defaults');
options.MaxIter = 1;
options.MaxFunEvals = 1;
options.LBounds = LB;
options.UBounds = UB;

if(parallel)
    options.EvalParallel = 'yes';
end

% Set guess point to be the mean of the bounds
InitialPopulation = ones(init_heat_map.count, 1) * mean([LB, UB]);

% The solution should be in the range of x0 +- 2 * sigma_0
% according to the cmaes documentation
sigma_0 = mean([LB, UB]) / 2;

% Path where the initial population will be saved
init_population_path = [paths_str.output_folder 'InitialPopulation.mat'];
save(init_population_path, 'InitialPopulation');

%% Call the CMAES solver
startTime = tic;

[heat_map_v, best_error, exitflag] = cmaes(fitness_foo, InitialPopulation, ...
    sigma_0, options);

% Cmaes solver uses column order, switch to row order for
% consistency with the other solvers
heat_map_v = heat_map_v';

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% Save summary file

summary_data.OptimizationMethod = 'CMAES';
summary_data.ImageError = best_error;
summary_data.HeatMapSize = init_heat_map.size;
summary_data.HeatMapNumVariables = init_heat_map.count;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
summary_data.LowerBounds = LB(1);
summary_data.UpperBounds = UB(1);
summary_data.InitGuessFile = init_population_path;
summary_data.sigma_0 = sigma_0;

save_summary_file(paths_str.summary, summary_data, options);


end

