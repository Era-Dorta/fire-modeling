function [ t, d, fval, exitFlag, output ] = icm_re_density ( fun, t0, d0, xyz, ...
    lbt, ubt, lbd, ubd, options)
%ICM_RE_DENSITY Iterative Conditional Modes resampling parallel solver

%% Initialisation
state = 'init';
exitFlag = 0;
num_dim = numel(t0);

% Temperature range, it will be gradually deacreased for each voxel
tlr = lbt;
tur = ubt;
dlr = lbd;
dur = ubd;

optimValues.fval = 1;
optimValues.iteration = 0;
optimValues.funccount = 0;
optimValues.procedure = 'Initial message';
optimValues.ite_inc = round(num_dim / 2);
optimValues.exposure = options.exposure;
optimValues.fexposure = options.fexposure;
optimValues.density = options.density;
optimValues.fdensity = options.fdensity;
optimValues.do_temperature = false;
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

optimValues = options.ExposureFnc(d0, optimValues, state);

% Put the same value in all clusters
for i=1:optimValues.ite_inc:num_dim
    ii = i:min(i+optimValues.ite_inc-1, num_dim);
    d0(ii) = mean(d0(ii));
    t0(ii) = mean(t0(ii));
end

[~, optimValues] = call_output_fnc_icm(d0, options, optimValues, state);

%% First "iteration" is just an evaluation of the initial point
% Changing the state and calling twice the output fnc is needed to
% replicate the behaviour of the other solvers
state = 'iter';

cur_score_pairwise_t = zeros(num_dim, 1);
cur_score_pairwise_d = zeros(num_dim, 1);

compute_pairwise_all(d0);

optimValues.do_temperature = true;

cur_score = calculate_score_all(t0, lbt, ubt);

optimValues.fval = mean(cur_score);

% Replicate x to be able to evaluate in parallel
t = repmat(t0, options.TemperatureNSamples, 1);
d = repmat(d0, options.TemperatureNSamples, 1);

optimValues = options.ClusterUpdateFnc(t0, options, optimValues, state);
[stop, optimValues] = call_output_fnc_icm(t0, options, optimValues, state);

display_info_icm(options, optimValues, num_dim);

%% Main loop
while(~stop)
    
    current_score = mean(cur_score);
    
    if optimValues.do_temperature
        
        % Iterate for each voxel
        for i=1:optimValues.ite_inc:num_dim
            ii = i:min(i+optimValues.ite_inc-1, num_dim);
            iis = numel(ii);
            % Get temperature for the current voxel
            cur_temp = t(1, i);
            
            % Assign a different temperature to each copy of x
            new_t = options.CreateSamplesFcn(i, t(1,:), optimValues, options, tlr, tur);
            t(:, ii) = repmat(new_t', 1, iis);
            
            % Compute all the scores
            new_score = calculate_score_approx(ii, t, lbt, ubt);
            
            % Get the min
            [new_score, j] = min(new_score);
            
            % Update on improvement
            if (new_score < cur_score(i))
                cur_temp = new_t(j);
                % Assign the new score to all ii voxels
                cur_score(ii) = new_score;
            end
            
            % Reset or update the voxel temperature
            t(:, ii) = cur_temp;
            
            [tlr, tur] = options.UpdateSampleRangeFcn(ii, cur_temp, new_t, tlr, tur);
            
        end
        
        optimValues = options.ExposureFnc(t(1,:), optimValues, state);
        
        % Update the score in case approximations where used
        cur_score = calculate_score_all(t(1,:), lbt, ubt);
        
        optimValues.fval = mean(cur_score);
        
        optimValues.iteration = optimValues.iteration + 1;
        
        optimValues = options.ClusterUpdateFnc(t(1,:), options, optimValues, state);
        cur_score = recompute_after_cluster_update(cur_score);
        
        [stop, optimValues] = call_output_fnc_icm(t, options, optimValues, state);
        if (stop)
            state = 'interrupt';
            exitFlag = -1;
        else
            [stop, optimValues] = check_exit_conditions_icm(options, optimValues, current_score);
        end
        
    else
        
        % Iterate for each voxel
        for i=1:optimValues.ite_inc:num_dim
            ii = i:min(i+optimValues.ite_inc-1, num_dim);
            iis = numel(ii);
            % Get temperature for the current voxel
            cur_d = d(1, i);
            
            % Assign a different temperature to each copy of x
            new_d = options.CreateSamplesFcn(i, d(1,:), optimValues, options, dlr, dur);
            d(:, ii) = repmat(new_d', 1, iis);
            
            % Compute all the scores
            new_score = calculate_score_approx(ii, d, lbd, ubd);
            
            % Get the min
            [new_score, j] = min(new_score);
            
            % Update on improvement
            if (new_score < cur_score(i))
                cur_d = new_d(j);
                % Assign the new score to all ii voxels
                cur_score(ii) = new_score;
            end
            
            % Reset or update the voxel temperature
            d(:, ii) = cur_d;
            
            [dlr, dur] = options.UpdateSampleRangeFcn(ii, cur_d, new_d, dlr, dur);
            
        end
        
        optimValues = options.ExposureFnc(d(1,:), optimValues, state);
        
        % Update the score in case approximations where used
        cur_score = calculate_score_all(d(1,:), lbd, ubd);
        
        optimValues.fval = mean(cur_score);
        
        optimValues.iteration = optimValues.iteration + 1;
        
        optimValues = options.ClusterUpdateFnc(d(1,:), options, optimValues, state);
        cur_score = recompute_after_cluster_update(cur_score);
        
        [stop, optimValues] = call_output_fnc_icm(d, options, optimValues, state);
        if (stop)
            state = 'interrupt';
            exitFlag = -1;
        else
            [stop, optimValues] = check_exit_conditions_icm(options, optimValues, current_score);
        end
        
    end
    
    optimValues.do_temperature = ~optimValues.do_temperature;
    
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

call_output_fnc_icm(t, options, optimValues, state);

% Remove the copies of x
t = t(1,:);
d = d(1,:);

%% Auxiliary functions
    function [score] = calculate_score_approx(i, x, lb, ub)
        
        score = data_term_score_approx(i, x, lb, ub);
        
        n_i = getNeighborsIndices_icm_re(i, xyz, options.NeighbourhoodSize);
        
        score = score + pairwise_term(i, n_i, x, lb, ub);
        
    end

    function [score] = data_term_score_approx(i, x, lb, ub)
        
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

    function [score] = calculate_score(i, x, lb, ub)
        
        score = data_term_score(i, x, lb, ub);
        
        n_i = getNeighborsIndices_icm_re(i, xyz, options.NeighbourhoodSize);
        
        score = score + pairwise_term(i, n_i, x, lb, ub);
        
    end

    function [score] = data_term_score(i, x, lb, ub)
        
        score = zeros(1, size(x, 1));
        
        for k=1:numel(options.DataTermFcn)
            [data_score, optimValues] = options.DataTermFcn{k}(i(1), x,  ...
                options, optimValues, lb, ub);
            score = score + data_score * options.DataTermFactors(k);
        end
        
    end

    function score = pairwise_term(i, n_i, x, lb, ub)
        
        score = zeros(1, size(x, 1));
        
        for k=1:numel(options.PairWiseTermFcn)
            score = score + options.PairWiseTermFcn{k}(i(1), n_i, x, options, ...
                lb, ub) * options.PairWiseTermFactors(k);
        end
        
        % Add the pairwise term of the other to the current to always have
        % a consistent score regardless of which one is being minimised
        if optimValues.do_temperature
            score = score + cur_score_pairwise_d(i(1));
        else
            score = score + cur_score_pairwise_t(i(1));
        end
    end

    function [score] = calculate_score_all(x, lb, ub)
        
        score = ones(num_dim, 1);
        
        % Compute data term only once for all the temperatures
        if(use_common_dataterm)
            
            for k=1:optimValues.ite_inc:num_dim
                kk = k:min(k+optimValues.ite_inc-1, num_dim);
                n_i = getNeighborsIndices_icm_re(kk, xyz, options.NeighbourhoodSize);
                
                score(kk) = pairwise_term(kk, n_i, x, lb, ub);
            end
            
            % Update the copy of the pairwise term
            if optimValues.do_temperature
                cur_score_pairwise_t = score - cur_score_pairwise_d;
            else
                cur_score_pairwise_d = score - cur_score_pairwise_t;
            end
            
            [data_score, optimValues] = options.DataTermFcn{1}(1, x,  ...
                options, optimValues, lb, ub);
            
            score = score + data_score * options.DataTermFactors(1);
            
        else
            for k=1:optimValues.ite_inc:num_dim
                kk = k:min(k+optimValues.ite_inc-1, num_dim);
                
                n_i = getNeighborsIndices_icm_re(kk, xyz, options.NeighbourhoodSize);
                
                score(kk) = pairwise_term(kk, n_i, x, lb, ub);
                
                if optimValues.do_temperature
                    cur_score_pairwise_t(kk) = score(kk) - cur_score_pairwise_d(kk);
                else
                    cur_score_pairwise_d(kk) = score(kk) - cur_score_pairwise_t(kk);
                end
                
                score(kk) = score(kk) + data_term_score(kk, x, lb, ub);
            end
        end
        
    end

    function compute_pairwise_all(x)
        
        if optimValues.do_temperature
            for k=1:optimValues.ite_inc:num_dim
                kk = k:min(k+optimValues.ite_inc-1, num_dim);
                n_i = getNeighborsIndices_icm_re(kk, xyz, options.NeighbourhoodSize);
                
                cur_score_pairwise_t(kk) = pairwise_term(kk, n_i, x, lbt, ubt);
            end
        else
            for k=1:optimValues.ite_inc:num_dim
                kk = k:min(k+optimValues.ite_inc-1, num_dim);
                n_i = getNeighborsIndices_icm_re(kk, xyz, options.NeighbourhoodSize);
                
                cur_score_pairwise_d(kk) = pairwise_term(kk, n_i, x, lbd, ubd);
            end
        end
        
    end

    function [cur_score] = recompute_after_cluster_update(cur_score)
        if(prev_ite_inc ~= optimValues.ite_inc)
            new_inc = optimValues.ite_inc;
            optimValues.ite_inc = prev_ite_inc;
            
            display_info_icm(options, optimValues, num_dim);
            
            optimValues.ite_inc = new_inc;
            prev_ite_inc = optimValues.ite_inc;
            
            cur_score = cur_score - cur_score_pairwise_d - cur_score_pairwise_t;
            
            prev_do_temp = optimValues.do_temperature;
            
            optimValues.do_temperature = true;
            cur_score_pairwise_d(:) = 0;
            compute_pairwise_all(t(1,:));
            
            optimValues.do_temperature = false;
            compute_pairwise_all(d(1,:));
            cur_score_pairwise_d = cur_score_pairwise_d - cur_score_pairwise_t;
            
            optimValues.do_temperature = prev_do_temp;
            
            cur_score = cur_score + cur_score_pairwise_d + cur_score_pairwise_t;
            
            optimValues.fval = mean(cur_score);
        end
    end

end

