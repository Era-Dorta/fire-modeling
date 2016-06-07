function [ heat_map_v, best_error, exitflag] = do_permute_solve( ...
    init_heat_map, fitnessFnc, paths_str, summary_data, goal_img, ...
    goal_mask, opts)
%DO_PERMUTE_SOLVE PERMUTE solver for heat map reconstruction
% Simple permutation based solver, use a gacreation function to create an
% initial population, on each iteratio permute the voxels of the current
% individual and keep the permutation if it is better than the previous one

%% Options preprocessing
exitflag = 0;
out_msg = 'done';

% Path where the initial population will be saved
output_data_path = [paths_str.output_folder 'OutputData.mat'];

options = get_ga_options_from_file( opts, init_heat_map,  ...
    goal_img, goal_mask, output_data_path, paths_str, false);

options.LinearConstr.lb = ones(init_heat_map.count, 1) * opts.LB;
options.LinearConstr.ub = ones(init_heat_map.count, 1) * opts.UB;
options.PopInitRange = [options.LinearConstr.lb'; options.LinearConstr.ub'];

best_error = 1;
GenomeLength = init_heat_map.count;

startTime = tic;

state = struct('Generation', 0, 'StartTime', startTime, 'StopFlag', [], 'Best', [], ...
    'FunEval', 0);

%% Population initialization

state.Population = options.CreationFcn( GenomeLength, [], options);
state.Score = fitnessFnc(state.Population)';
[state.Best, best_idx] = min(state.Score);
state.FunEval = options.PopulationSize;

% Parent for each individual is itself
parents = 1:options.PopulationSize;

call_output_fnc('init');
check_exit_conditions();

disp('Iter F-count           f(x)');

% Output init data
fprintf('init %7d    %.5e\n', state.FunEval, state.Best(end));

%% Main optimization
while(exitflag == 0)
    
    % Permute and eval population
    new_population = options.MutationFcn(parents, options, ...
        GenomeLength, fitnessFnc, state, state.Score, state.Population);
    new_scores = fitnessFnc(new_population)';
    
    % Update the state
    subs_idx = new_scores < state.Score;
    state.Population(subs_idx, :) = new_population(subs_idx, :);
    state.Score(subs_idx) = new_scores(subs_idx);
    
    [best_score, best_idx] = min(state.Score);
    state.Best = [state.Best, best_score];
    state.Generation = state.Generation + 1;
    state.FunEval = state.FunEval + options.PopulationSize;
    
    % Output iteration data
    fprintf('% 4d %7d    %.5e\n', state.Generation, state.FunEval, state.Best(end));
    
    % Call output and plot functions
    call_output_fnc('iter');
    
    check_exit_conditions();
end

totalTime = toc(startTime);
disp(['Optimization finished, ' out_msg ', total time ' num2str(totalTime)]);

call_output_fnc('done');

FinalPopulation = state.Population;
FinalScores = state.Score;

heat_map_v = FinalPopulation(best_idx, :);
best_error = state.Best(end);

%% Save data to file
save(output_data_path, 'FinalPopulation', 'FinalScores', '-append');

%% Visualize distance space
visualize_score_space(output_data_path, paths_str.visualization_fig_path);

%% Save summary file
% In the summary file just say were the init population file was saved
summary_data.OptimizationMethod = 'Genetic Algorithms';
summary_data.ImageError = state.Best(end);
summary_data.HeatMapSize = init_heat_map.size;
summary_data.HeatMapNumVariables = init_heat_map.count;
summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
summary_data.OuputDataFile = output_data_path;
summary_data.options.InitialPopulation = output_data_path;

save_summary_file(paths_str.summary, summary_data, []);

    function call_output_fnc(flag)
        for i=1:numel(options.OutputFcns)
            [state, options_new, optchanged] = options.OutputFcns{i}(options, state, flag);
            if optchanged
                options = options_new;
            end
            if exitflag == 0 && ~isempty(state.StopFlag)
                out_msg = state.StopFlag;
                exitflag = -1;
            end
        end
    end

    function check_exit_conditions()
        if exitflag == 0
            if state.Generation >= options.Generations
                out_msg = 'max generations exceeded';
                exitflag = 1;
            elseif best_error < options.FitnessLimit;
                out_msg = 'fitness function reached FitnessLimit';
                exitflag = 1;
            elseif numel(best_error) >= 2 && abs(best_error(end - 1) - ...
                    best_error(end)) > options.TolFun;
                exitflag = 1;
                out_msg = 'change in fitness function smaller than TolFun';
            end
        end
    end

end

