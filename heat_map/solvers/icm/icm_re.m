function [ x, fval, exitFlag, output ] = icm_re ( fun, x0, xyz, lb, ub, options)
%ICM_RE Iterative Conditional Modes resampling parallel solver

%% Initialisation
state = 'init';
exitFlag = 0;
num_dim = numel(x0);

% Temperature range, it will be gradually deacreased for each voxel
tlr = lb;
tur = ub;

optimValues.fval = 1;
optimValues.iteration = 0;
optimValues.funccount = 0;
optimValues.procedure = 'Initial message';
optimValues.ite_inc = round(num_dim / 2);
optimValues.exposure = options.exposure;
optimValues.fexposure = options.fexposure;
optimValues.density = options.density;
optimValues.fdensity = options.fdensity;

prev_ite_inc = optimValues.ite_inc;

if options.DataTermEvalVM > 0.5
    % More than 50% evaluations, use random generator
    options.DataTermEvalVMRand = true;
else
    % Less than 50% use mod to eval without probabilities
    options.DataTermEvalVMRand = false;
    options.DataTermEvalVM = round(1 / options.DataTermEvalVM);
end

if(options.TemperatureNSamples < 1)
    exitFlag = -1;
    optimValues.procedure = 'TemperatureNSamples must be >= 1';
    disp(optimValues.procedure);
    return;
end

% If data term function is eval render, just render once as the
% values are not changing
if(isempty(options.DataTermFcn) || (numel(options.DataTermFcn) == 1 ...
        && ~isempty(strfind(func2str(options.DataTermFcn{1}), ...
        'eval_render_function_always_icm'))))
    use_common_dataterm = true;
else
    use_common_dataterm = false;
end

optimValues = options.DensityFnc(x0, optimValues, state);
optimValues = options.ExposureFnc(x0, optimValues, state);

[~, optimValues] = call_output_fnc_icm(x0, options, optimValues, state);

%% First "iteration" is just an evaluation of the initial point
% Changing the state and calling twice the output fnc is needed to
% replicate the behaviour of the other solvers
state = 'iter';

cur_score = calculate_score_all(x0);

optimValues.fval = mean(cur_score);

% Replicate x to be able to evaluate in parallel
x = repmat(x0, options.TemperatureNSamples, 1);

optimValues = options.ClusterUpdateFnc(x(1,:), options, optimValues, state);
[stop, optimValues] = call_output_fnc_icm(x, options, optimValues, state);

display_info_icm(options, optimValues, num_dim);

%% Main loop
while(~stop)
    
    current_score = mean(cur_score);
    
    % Iterate for each voxel
    for i=1:optimValues.ite_inc:num_dim
        ii = i:min(i+optimValues.ite_inc-1, num_dim);
        iis = numel(ii);
        % Get temperature for the current voxel
        cur_temp = x(1, i);
        
        % Assign a different temperature to each copy of x
        t = options.CreateSamplesFcn(i, x(1,:), optimValues, options, tlr, tur);
        x(:, ii) = repmat(t', 1, iis);
        
        % Compute all the scores
        new_score = calculate_score_approx(ii, x);
        
        % Get the min
        [new_score, j] = min(new_score);
        
        % Update on improvement
        if (new_score < cur_score(i))
            cur_temp = t(j);
            % Assign the new score to all ii voxels
            cur_score(ii) = new_score;
        end
        
        % Reset or update the voxel temperature
        x(:, ii) = cur_temp;
        
        [tlr, tur] = options.UpdateSampleRangeFcn(ii, cur_temp, t, tlr, tur);
        
    end
    
    optimValues = options.DensityFnc(x(1,:), optimValues, state);
    optimValues = options.ExposureFnc(x(1,:), optimValues, state);
    
    % Update the score in case approximations where used
    cur_score = calculate_score_all(x(1,:));
    
    optimValues.fval = mean(cur_score);
    
    optimValues.iteration = optimValues.iteration + 1;
    
    optimValues = options.ClusterUpdateFnc(x(1,:), options, optimValues, state);
    cur_score = recompute_after_cluster_update(x(1,:), cur_score);
    
    [stop, optimValues] = call_output_fnc_icm(x, options, optimValues, state);
    if (stop)
        state = 'interrupt';
        exitFlag = -1;
    else
        [stop, optimValues] = check_exit_conditions_icm(options, optimValues, current_score);
    end
    
    display_info_icm(options, optimValues, num_dim);
end

%% Clean up, exit state
disp(optimValues.procedure);

state = 'done';
fval = optimValues.fval;

output = struct('funcCount', optimValues.funccount, 'iterations', ...
    optimValues.iteration, 'message', optimValues.procedure, 'exposure', ...
    optimValues.exposure, 'fexposure', optimValues.fexposure, 'density', ...
    optimValues.density, 'fdensity', optimValues.fdensity,'tlr', tlr, ...
    'tur', tur);

call_output_fnc_icm(x, options, optimValues, state);

% Remove the copies of x
x = x(1,:);

%% Auxiliary functions
    function [score] = calculate_score_approx(i, x)
        
        score = data_term_score_approx(i, x);
        
        n_i = getNeighborsIndices_icm_re(i, xyz, options.NeighbourhoodSize);
        
        score = score + pairwise_term(i, n_i, x);
        
    end

    function [score] = data_term_score_approx(i, x)
        
        score = zeros(1, size(x, 1));
        
        for k=1:numel(options.DataTermFcn)
            % Call the function with the first voxel index i(1), all the i
            % have the same temperatures, so they will all share the score
            % as they are considered to be clustered together, the same
            % applies to DataTermFcn and PairWiseTermFcn
            [data_score, optimValues] = options.DataTermApproxFcn{k}(i(1), x,  ...
                options, optimValues, lb, ub);
            score = score + data_score * options.DataTermApproxFactors(k);
        end
        
    end

    function [score] = calculate_score(i, x)
        
        score = data_term_score(i, x);
        
        n_i = getNeighborsIndices_icm_re(i, xyz, options.NeighbourhoodSize);
        
        score = score + pairwise_term(i, n_i, x);
        
    end

    function [score] = data_term_score(i, x)
        
        score = zeros(1, size(x, 1));
        
        for k=1:numel(options.DataTermFcn)
            [data_score, optimValues] = options.DataTermFcn{k}(i(1), x,  ...
                options, optimValues, lb, ub);
            score = score + data_score * options.DataTermFactors(k);
        end
        
    end

    function score = pairwise_term(i, n_i, x)
        
        score = zeros(1, size(x, 1));
        
        for k=1:numel(options.PairWiseTermFcn)
            score = score + options.PairWiseTermFcn{k}(i(1), n_i, x, options, ...
                lb, ub) * options.PairWiseTermFactors(k);
        end
        
    end

    function [score] = calculate_score_all(x)
        
        score = ones(num_dim, 1);
        
        % Compute data term only once for all the temperatures
        if(use_common_dataterm)
            
            [data_score, optimValues] = options.DataTermFcn{1}(1, x,  ...
                options, optimValues, lb, ub);
            
            score(:) = data_score * options.DataTermFactors(1);
            
            for k=1:optimValues.ite_inc:num_dim
                kk = k:min(k+optimValues.ite_inc-1, num_dim);
                n_i = getNeighborsIndices_icm_re(kk, xyz, options.NeighbourhoodSize);
                
                score(kk) = score(kk) + pairwise_term(kk, n_i, x);
            end
            
        else
            for k=1:optimValues.ite_inc:num_dim
                kk = k:min(k+optimValues.ite_inc-1, num_dim);
                score(kk) = calculate_score(kk, x);
            end
        end
        
    end

    function [score] = recompute_after_cluster_update(x, score)
        if(prev_ite_inc ~= optimValues.ite_inc)
            new_inc = optimValues.ite_inc;
            optimValues.ite_inc = prev_ite_inc;
            
            display_info_icm(options, optimValues, num_dim);
            
            optimValues.ite_inc = new_inc;
            prev_ite_inc = optimValues.ite_inc;
            
            score = calculate_score_all(x);
            
            optimValues.fval = mean(score);
        end
    end

end

