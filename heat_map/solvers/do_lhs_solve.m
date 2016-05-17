function [ heat_map_v, best_error, exitflag] = do_lhs_solve( ...
    init_heat_map, fitness_foo, paths_str, summary_data, L)
%DO_LHS_SOLVE LHS solver for heat map reconstruction
% Simple Latin Hypercube Sampler solver, randomly samples the space and
% takes the best individual

%% Options for the LHS
options = L.options;

exitflag = 1;

% Create the latin hypercube of heat map samples in the range [0,1]
lhs = lhsdesign(options.MaxIter, init_heat_map.count);

% Scale the lhs to span [LB, UB]
for i=1:options.MaxIter
    lhs(i,:) = fitToRange(lhs(i,:), 0, 1, L.LB, L.UB);
end

best_error = Inf;
best_idx = 1;

%% Check the fitness of each point

startTime = tic;

c_batch_s_idx = 1;
c_batch_e_idx = min(options.BatchEval, options.MaxIter);

disp('Iter F-count           f(x)');
i = 1;
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
    
    fprintf('% 4d %7d    %.5e\n', i, c_batch_s_idx -1, best_error);
    if mod(i, 25) == 0
        disp('Iter F-count           f(x)');
    end
    
    if(toc(startTime) > L.time_limit)
        exitflag = -1;
        break;
    end
    i = i + 1;
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

save_summary_file(paths_str.summary, summary_data, []);
end

