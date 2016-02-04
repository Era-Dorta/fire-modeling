function [ heat_map_v, best_error, exitflag] = do_lhs_solve( ...
    max_ite, time_limit, LB, UB, init_heat_map, fitness_foo, paths_str, ...
    summary_data)
%DO_LHS_SOLVE LHS solver for heat map reconstruction
% Simple Latin Hypercube Sampler solver, randomly samples the space and
% takes the best individual

%% Options for the LHS
% Get default values
options.MaxIter = max_ite;
options.TolFun = 0.0001;
options.LB = LB;
options.UB = UB;
options.BatchEval = 20;

exitflag = 1;

% Create the latin hypercube of heat map samples
lhs = lhsdesign(options.MaxIter, init_heat_map.count);

for i=1:options.MaxIter
    lhs(i,:) = fitToRange(lhs(i,:), 0, 1, LB, UB);
end

best_error = Inf;
best_idx = 1;

%% Check the fitness of each point

startTime = tic;

c_batch_s_idx = 1;
c_batch_e_idx = min(options.BatchEval, options.MaxIter);

% Do the check in batches, if we find a solution then we can exit early
while(c_batch_s_idx <= options.MaxIter && best_error > options.TolFun)
    
    c_batch_error = feval(fitness_foo, lhs(c_batch_s_idx:c_batch_e_idx, :));
    [min_c_error, min_c_idx] = min(c_batch_error);
    
    if(min_c_error < best_error)
        best_error = min_c_error;
        best_idx = min_c_idx + c_batch_s_idx - 1;
    end
    
    c_batch_s_idx = c_batch_s_idx + options.BatchEval;
    c_batch_e_idx = min(c_batch_e_idx + options.BatchEval, options.MaxIter);
    
    if(toc(startTime) > time_limit)
        exitflag = -1;
        break;
    end
end

heat_map_v = lhs(best_idx, :);

totalTime = toc(startTime);
disp(['Optimization total time ' num2str(totalTime)]);

%% Save summary file

summary_data.OptimizationMethod = 'Latin Hypercube Sampler';
summary_data.ImageError = best_error;
summary_data.HeatMapSize = init_heat_map.size;
summary_data.HeatMapNumVariables = init_heat_map.count;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
summary_data.LowerBounds = LB(1);
summary_data.UpperBounds = UB(1);

save_summary_file(paths_str.summary, summary_data, options);


end

