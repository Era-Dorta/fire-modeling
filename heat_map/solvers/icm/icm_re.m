function [ x, fval, exitFlag, output ] = icm_re ( fun, x0, xyz, lb, ub, options)
%ICM_RE Iterative Conditional Modes parallel solver

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

display_info_icm(options, optimValues, num_dim);

optimValues = options.ExposureFnc(x0, optimValues, state);
[stop, optimValues] = call_output_fnc_icm(x, options, optimValues, state);

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
            cur_score(ii) = new_score;
        end
        
        % Reset or update the voxel temperature
        x(:, ii) = cur_temp;
        
        [tlr, tur] = options.UpdateSampleRangeFcn(ii, cur_temp, t, tlr, tur);
        
    end
    
    % Update the score in case approximations where used
    cur_score = calculate_score_all(x(1,:));
    
    optimValues.fval = mean(cur_score);
    
    optimValues.iteration = optimValues.iteration + 1;

    optimValues = options.ExposureFnc(x0, optimValues, state);
    
    display_info_icm(options, optimValues, num_dim);
    
    [stop, optimValues] = call_output_fnc_icm(x, options, optimValues, state);
    if (stop)
        state = 'interrupt';
        exitFlag = -1;
    else
        [stop, optimValues] = check_exit_conditions_icm_re(options, optimValues, current_score);
    end
    
end

%% Clean up, exit state
disp(optimValues.procedure);

state = 'done';
fval = optimValues.fval;

output = struct('funcCount', optimValues.funccount, 'iterations', ...
    optimValues.iteration, 'message', optimValues.procedure, 'exposure', ...
    optimValues.exposure, 'fexposure', optimValues.fexposure, 'tlr', tlr, ...
    'tur', tur);

call_output_fnc_icm(x, options, optimValues, state);

% Remove the copies of x
x = x(1,:);

%% Auxiliary functions
    function [score] = calculate_score_approx(i, x)
        
        score = data_term_score_approx(i, x);
        
        n_i = getNeighborsIndices_icm(i, xyz, options.NeighbourhoodSize);
        
        score = score + pairwise_term(i, n_i, x);
        
    end

    function [score] = data_term_score_approx(i, x)
        
        score = zeros(1, size(x, 1));
        
        for k=1:numel(options.DataTermFcn)
            [data_score, optimValues] = options.DataTermApproxFcn{k}(i, x,  ...
                options, optimValues, lb, ub);
            score = score + data_score * options.DataTermApproxFactors(k);
        end
        
    end

    function [score] = calculate_score(i, x)
        
        score = data_term_score(i, x);
        
        n_i = getNeighborsIndices_icm(i, xyz, options.NeighbourhoodSize);
        
        score = score + pairwise_term(i, n_i, x);
        
    end

    function [score] = data_term_score(i, x)
        
        score = zeros(1, size(x, 1));
        
        for k=1:numel(options.DataTermFcn)
            [data_score, optimValues] = options.DataTermFcn{k}(i, x,  ...
                options, optimValues, lb, ub);
            score = score + data_score * options.DataTermFactors(k);
        end
        
    end

    function score = pairwise_term(i, n_i, x)
        
        score = zeros(1, size(x, 1));
        
        for k=1:numel(options.PairWiseTermFcn)
            score = score + options.PairWiseTermFcn{k}(i, n_i, x, options, ...
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
            
            for k=1:num_dim
                n_i = getNeighborsIndices_icm(k, xyz, options.NeighbourhoodSize);
                
                score(k) = score(k) + pairwise_term(k, n_i, x);
            end
            
        else
            for k=1:num_dim
                score(k) = calculate_score(k, x);
            end
        end
        
    end

end

