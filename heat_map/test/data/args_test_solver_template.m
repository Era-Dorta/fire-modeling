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

max_ite = 5000; % Num of maximum iterations
time_limit = 2 * 60 * 60; % Two hours

switch solver
    case {'ga', 'ga-re'}
        % Get an empty gaoptions structure
        options = gaoptimset;
        options.PopulationSize = 200;
        options.Generations = 25;
        options.TimeLimit = time_limit;
        options.Display = 'iter'; % Give some output on each iteration
        options.StallGenLimit = 1;
        options.Vectorized = 'on';
        
        % One of @gacreationheuristic1, @gacreationrandom, @gacreationfrominitguess
        % @gacreationlinspace, @gacreationuniform, @gacreationlinearfeasible
        % @gacreationfrominitguess needs the variables creation_fnc_mean and
        % creation_fnc_sigma to be saved in the solver.mat file as well.
        options.CreationFcn = @gacreationheuristic1;
        
        % One of @crossoverscattered ,@crossoversinglepoint, @crossovertwopoint
        % @crossoverintermediate, @crossoverheuristic, @gacrossovercombine
        % @gacrossovercombineprior, @gaxoverpriorhisto
        options.CrossoverFcn = @gacrossovercombineprior;
        
        % One of @gamutationadaptprior, @mutationadaptfeasible,
        % @gamutationnone, @gamutationadaptscale, @gamutationmean,
        % @crossoverheuristic, @mutationgaussian, @mutationuniform,
        % @mutationadaptfeasible
        options.MutationFcn = @mutationadaptfeasible;
        
        % Any of @gaplotbestcustom, @ga_time_limit, @gaplotbestgen
        options.OutputFcns = {@gaplotbestcustom, @gaplotbestgen, ...
            @ga_time_limit};
        
        if isequal(solver, 'ga-re') % Extra parameters for GA resampling
            % Functions for the first GA iteration
            CreationFcnFirst = options.CreationFcn;
            CrossoverFcnFirst = options.CrossoverFcn;
            MutationFcnFirst = options.MutationFcn;
            
            % Functions for the rest
            options.CreationFcn = @gacreationfrominitguess;
            options.CrossoverFcn = @gacrossovercombineprior;
            options.MutationFcn = @mutationadaptfeasible;
            
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
            save(args_path, '-regexp','^(?!(args_path|solver)$).');
        end
    case 'sa'
        % Get default values
        options = saoptimset('simulannealbnd');
        options.MaxIter = max_ite;
        options.MaxFunEvals = max_ite;
        options.TimeLimit = time_limit;
        options.InitialTemperature = 1/6; % Factor to multiply (UB - LB)
        options.Display = 'iter'; % Give some output on each iteration
        
        % Only sa_time_limit
        options.OutputFcns = @sa_time_limit;
    case 'grad'
        % Get default values
        options = optimoptions(@fmincon);
        
        options.MaxIter = max_ite;
        options.MaxFunEvals = max_ite;
        options.Display = 'iter-detailed'; % Give some output on each iteration
        
        options.OutputFcn = @gradient_time_limit;
    case 'cmaes'
        % Get default values
        options = cmaes('defaults');
        options.MaxIter = max_ite;
        options.MaxFunEvals = max_ite;
        options.EvalParallel = 'yes';
        
        % Disable saving any data files
        options.SaveVariables = 'off';
        options.LogModulo = 0;
        options.LogTime = 0;
        
        % For high dimensional problems optimize only the diagonal of the
        % covariance matrix 
        options.DiagonalOnly = 1;

        % Default is -Inf but our error function is minimum value is 0
        options.StopFitness = eps;
    case 'lhs'
        % Get default values
        options.MaxIter = max_ite;
        options.TolFun = 0.0001;
        options.BatchEval = 20;
    otherwise
        solver_names = ['[''ga'', ''sa'', ''ga-re'', ''grad'', ''cmaes'',' ...
        ' ''lhs'']'];
        error(['Invalid solver, choose one of ' solver_names ]);
end

% Save all but args_path and solver
save(args_path, '-regexp','^(?!(args_path|solver)$).');

end
