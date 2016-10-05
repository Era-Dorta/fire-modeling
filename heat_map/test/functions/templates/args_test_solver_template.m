function args_test_solver_template(args_path, solver)
%ARGS_TEST_SOLVER_TEMPLATE Arguments for heatMapReconstruction
%   ARGS_TEST_SOLVER_TEMPLATE(ARGS_PATH, SOLVER) Saves in ARGS_PATH the file path
%   of a  .mat file with arguments defined here for a given SOLVER.
%   SOLVER should be one of the following
%   'ga' -> Genetic Algorithm
%   'sa' -> Simulated Annealing
%   'ga-re' -> Genetic Algorithm with heat map resampling
%   'grad' -> Gradient Descent
%
%   See also args_test_template

max_ite = 4800; % Num of maximum iterations
maxFunEvals = max_ite; % Maximum number of allowed function evaluations
time_limit = 2 * 60 * 60; % Two hours

switch solver
    case {'ga', 'ga-re'}
        % Get an empty gaoptions structure
        options = gaoptimset(@ga);
        options.PopulationSize = 400;
        options.Generations = 20;
        options.TimeLimit = time_limit;
        options.Display = 'iter'; % Give some output on each iteration
        options.StallGenLimit = 3;
        options.Vectorized = 'on';
        
        % One of the following:
        % @gacreationrandom, @gacreationfrominitguess, @gacreationlinspace,
        % @gacreationuniform, @gacreationlinearfeasible,
        % @gacreationheuristic1, @gacreationheuristic2,
        % @gacreationheuristic3, @gacreationheuristic4,
        % @gacreationfrominitguess needs the variables creation_fnc_mean,
        % and creation_fnc_sigma to be saved in the solver.mat file as well.
        options.CreationFcn = @gacreationheuristic3;
        
        creation_fnc_n_bins = 255;
        
        % One of @crossoverscattered ,@crossoversinglepoint, @crossovertwopoint
        % @crossoverintermediate, @crossoverheuristic, @gacrossovercombine
        % @gacrossovercombineprior, @gacrossovercombine2
        options.CrossoverFcn = @gacrossovercombineprior;
        
        % If using gacrossovercombineprior the following have to be defined
        
        % Number of candidates for prior functions evaluation
        xover_nCandidates = 10;
        
        % Prior functions smoothnessEstimateGrad, upHeatEstimate,
        % histogramErrorApprox, upHeatEstimateLinear, downHeatEstimate
        xover_prior_fncs = {@smoothnessEstimateGrad, @diffToHeatMapWithNeigh};
        
        % Weights used to sum the error function and the prior functions
        xover_prior_weights = [0.4, 0.6];
        
        % Temperature threshold for the upHeatEstimateLinear
        xover_temp_th = 50;
        
        % One of @gamutationadaptprior, @gamutationnone, @gamutationscaleprior
        % @gamutationadaptscale, @gamutationscaleprior, @mutationgaussian,
        % @mutationuniform, @mutationadaptfeasible
        options.MutationFcn = @gamutationadaptprior;
        
        % If using gamutationadaptprior the following have to be defined
        mut_nCandidates = 10;
        mut_prior_fncs = {@smoothnessEstimateGrad, @diffToHeatMapWithNeigh};
        mut_prior_weights = [0.4, 0.6];
        mut_temp_th = 50;
        
        % Probability of for any gene to be mutated, used in
        % gamutationscaleprior
        mut_rate = 0.03;
        
        % Any of @gaplotbestcustom, @ga_time_limit, @gaplotbestgen,
        % @ga_max_fnc_eval_limit, @gasavescores
        options.OutputFcns = {@gaplotbestcustom, @gaplotbestgen, ...
            @ga_time_limit, @ga_max_fnc_eval_limit, @gasavescores};
        
        if isequal(solver, 'ga-re') % Extra parameters for GA resampling
            % Functions for the first GA iteration
            CreationFcnFirst = options.CreationFcn;
            CrossoverFcnFirst = options.CrossoverFcn;
            MutationFcnFirst = options.MutationFcn;
            
            % Functions for the rest
            options.CreationFcn = @gacreationfrominitguess;
            options.CrossoverFcn = @gacrossovercombineprior;
            options.MutationFcn = @gamutationadaptprior;
            
            creation_fnc_mean = 0;
            creation_fnc_sigma = 250;
            
            % The volume size will be at least this small, as we are recursively
            % dividing by 2 the original size, it might be smaller if there is no
            % integer i such that init_heat_map.size / 2^i == minimumVolumeSize
            minimumVolumeSize = 32;
            
            % Population size for the maximum resolution
            populationInitSize = 100;
            
            % Factor by which the population increases for a GA run with half of the
            % resolution, population of a state i will be initSize * (scale ^ i)
            populationScale = 2;
            
            % Upper limit for the population size of any resolution
            maxPopulation = 200;
            
            % Save all but args_path and solver
            save(args_path, '-regexp','^(?!(args_path|solver)$).', '-append');
        end
    case 'sa'
        % Get default values
        options = saoptimset('simulannealbnd');
        options.MaxIter = max_ite;
        options.MaxFunEvals = maxFunEvals;
        options.TimeLimit = time_limit;
        options.InitialTemperature = 1/6; % Factor to multiply (UB - LB)
        options.Display = 'iter'; % Give some output on each iteration
        
        % Only sa_time_limit
        options.OutputFcns = @sa_time_limit;
    case 'grad'
        % Get default values
        options = optimset(@fminsearch);
        
        options.MaxIter = max_ite;
        options.MaxFunEvals = maxFunEvals;
        options.Display = 'iter'; % Give some output on each iteration
        
        % @gradient_time_limit, @gradplotbestgen, @gradsavescores,
        % @gradploterror, @gradestimate_density_scale
        options.OutputFcn = {@gradient_time_limit, @gradplotbestgen, ...
            @gradsavescores, @gradploterror};
        
        % @random_guess_icm, @getInitHeatMap_icm, @getMeanTemp_icm,
        % @getInitHeatMapScaled_icm
        initGuessFnc = @random_guess_icm;
    case 'cmaes'
        % Get default values
        options = cmaes('defaults');
        options.MaxIter = max_ite;
        options.MaxFunEvals = maxFunEvals;
        options.EvalParallel = 'yes';
        
        % Disable saving any data files
        options.SaveVariables = 'off';
        options.LogModulo = 0;
        options.LogTime = 0;
        
        % If we want plots of the variance, re-enable the data saving and
        % the LogPlot to 'on'.
        % options.LogPlot = 'on';
        
        % For high dimensional problems optimize only the diagonal of the
        % covariance matrix
        options.DiagonalOnly = 1;
        
        % Default is -Inf but our error function is minimum value is 0
        options.StopFitness = eps;
    case 'lhs'
        % Get default values
        options.MaxIter = max_ite;
        options.TolFun = 0.0001;
        options.BatchEval = 200;
    case {'permute', 'permute_ga'}
        % Permute uses GA options struct
        % Get an empty gaoptions structure
        options = gaoptimset(@ga);
        options.PopulationSize = 200;
        options.Generations = 20;
        options.TimeLimit = time_limit;
        options.Display = 'iter'; % Give some output on each iteration
        options.StallGenLimit = 3;
        options.Vectorized = 'on';
        
        options.CreationFcn = @gacreationheuristic3;
        
        creation_fnc_n_bins = 255;
        
        % Only function allowed
        options.MutationFcn = @gamutationpermute;
        
        % If using gamutationadaptprior the following have to be defined
        mut_nCandidates = 10;
        mut_prior_fncs = {@smoothnessEstimateGrad, @diffToHeatMap};
        mut_prior_weights = [0.4, 0.6];
        mut_temp_th = 50;
        mut_rate = 0.03;
        
        % Any of @gaplotbestcustom, @ga_time_limit, @gaplotbestgen,
        % @ga_max_fnc_eval_limit, @gasavescores
        options.OutputFcns = {@gaplotbestcustom, @gaplotbestgen, ...
            @ga_time_limit, @ga_max_fnc_eval_limit, @gasavescores};
    case 'permute_ga_float'
        options = gaoptimset(@ga);
        options.PopulationSize = 200;
        options.Generations = 20;
        options.TimeLimit = time_limit;
        options.Display = 'iter'; % Give some output on each iteration
        options.StallGenLimit = 3;
        options.Vectorized = 'on';
        options.CreationFcn = @gacreationrandom;
        
        options.OutputFcns = {@gaplotbestcustom, @gaplotbestgen, ...
            @ga_time_limit, @ga_max_fnc_eval_limit, @gasavescores};
        
        initCreationFnc = @gacreationheuristic3;
        creation_fnc_n_bins = 255;
    case {'icm', 'icm-re'}
        options = struct();
        options.MaxIterations = max_ite;
        options.MaxFunctionEvaluations = maxFunEvals;
        options.Display = 'iter'; % Give some output on each iteration
        options.FunctionTolerance = 1e-6;
        options.TemperatureNSamples = 25;
        % 0 -> 6 neighbours, 1 -> 18, 2 -> 26, 3 -> 124, etc
        options.NeighbourhoodSize = 0;
        
        % @generate_random_temperatures_icm, @generate_linspace_temperatures_icm
        % @generate_gaussian_temperatures_icm
        options.CreateSamplesFcn = @generate_linspace_temperatures_icm;
        
        options.GenTempStd = 200;
        
        % @linear_range_reduce_temperature_icm, @update_range_none_icm
        options.UpdateSampleRangeFcn = @linear_range_reduce_temperature_icm;
        
        % @zero_data_term_icm, @eval_render_function_always_icm,
        % @eval_render_function_half_ite_icm, @rand_data_term_icm
        options.DataTermFcn = {@eval_render_function_always_icm};
        
        % Factor that multiplies the result of each data term
        options.DataTermFactors = [1];
        
        % @zero_data_term_icm, @eval_render_function_always_icm,
        % @eval_render_function_half_ite_icm
        options.DataTermApproxFcn = {};
        
        % Factor that multiplies the result of each data term
        options.DataTermApproxFactors = [];
        
        % For use with eval_render_function_half_ite_icm, number of voxels
        % that use the real eval function
        % 0 -> 0%, 0.5 -> 50%, 1 -> 100%
        options.DataTermEvalVM = 0.50;
        
        % @neighbour_distance_term_icm, @zero_pairwise_score_icm,
        % @neighbour_distance_exp_term_icm, @neighbour_distance_exp2_term_icm
        options.PairWiseTermFcn = {@neighbour_distance_term_icm};
        
        % Used with neighbour_distance_exp_term_icm, min 1, larger values
        % cause larger distances to be penalised more
        options.NeighDistExpFactor = [20, 1];
        
        % Factor that multiplies the result of each pairwise term
        options.PairWiseTermFactors = [1];
        
        % @gradient_time_limit, @gradplotbestgen, @gradsavescores,
        % @gradploterror, @gradestimate_density_scale
        options.OutputFcn = {@gradient_time_limit, @gradplotbestgen, ...
            @gradsavescores, @gradploterror};
        
        % @icm_estimate_exposure_scale, @icm_estimate_exposure_none
        options.ExposureFnc = @icm_estimate_exposure_scale;
        
        options.GenExposureStd = 100;
        
        % @icm_estimate_density_scale, @icm_estimate_density_none
        options.DensityFnc = @icm_estimate_density_scale;
        
        options.GenDensityStd = 100;
        
        % @random_guess_icm, @getInitHeatMap_icm, @getMeanTemp_icm,
        % @getInitHeatMapScaled_icm
        initGuessFnc = @random_guess_icm;
    otherwise
        solver_names = ['[''ga'', ''sa'', ''ga-re'', ''grad'', ''cmaes'',' ...
            ' ''lhs'', ''icm'', ''icm-re'']'];
        error(['Invalid solver, choose one of ' solver_names ]);
end

% Save all but args_path and solver
save(args_path, '-regexp','^(?!(args_path|solver)$).', '-append');

end
