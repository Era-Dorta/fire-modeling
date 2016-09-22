function [ x, fval, exitFlag, output ] = icm ( fun, x0, xyz, lb, ub, options)
%ICM Iterative Conditional Modes parallel solver

%% Initialisation
state = 'init';
exitFlag = 0;
num_dim = numel(x0);

% Temperature range, it will be gradually deacreased for each voxel
tlr = lb;
tur = ub;

optimValues.fval = 1;
optimValues.iteration = 0;
optimValues.funcCount = 0;
optimValues.message = 'Initial message';

if(options.TemperatureNSamples < 1)
    exitFlag = -1;
    optimValues.message = 'TemperatureNSamples must be >= 1';
    disp(optimValues.message);
    return;
end

x = x0;
[~, optimValues] = call_output_fnc_icm(x, options, optimValues, state);

%% First "iteration" is just an evaluation of the initial point
% Changing the state and calling twice the output fnc is needed to
% replicate the behaviour of the other solvers
state = 'iter';

cur_score = calculate_score_all();

optimValues.fval = mean(cur_score);

% Replicate x to be able to evaluate in parallel
x = repmat(x0, options.TemperatureNSamples, 1);

% Copy the data using an interpolant for easy access using the xyz coords
x_interp = scatteredInterpolant(xyz(:, 1), xyz(:, 2), xyz(:, 3), ...
    x0', 'nearest', 'none' );
warning('off', 'MATLAB:scatteredInterpolant:InterpEmptyTri3DWarnId');

display_info_icm(options, optimValues);

[stop, optimValues] = call_output_fnc_icm(x, options, optimValues, state);

%% Main loop
while(~stop)
    
    current_score = mean(cur_score);
    
    % Iterate for each voxel
    for i=1:num_dim
        
        % Get temperature for the current voxel
        cur_temp = x(1, i);
        
        % Assign a different temperature to each copy of x
        t = options.CreateSamplesFcn(i, options, tlr, tur);
        x(:, i) = t;
        
        % Compute all the scores
        new_score = calculate_score(i);
        
        % Get the min
        [new_score, j] = min(new_score);
        
        % Update on improvement
        if (new_score < cur_score(i))
            cur_temp = t(j);
            cur_score(i) = new_score;
            x_interp.Values(i) = cur_temp;
        end
        
        % Reset or update the voxel temperature
        x(:, i) = cur_temp;
        
        [tlr, tur] = options.UpdateSampleRangeFcn(i, cur_temp, t, tlr, tur);
        
    end
    
    optimValues.fval = mean(cur_score);
    
    optimValues.iteration = optimValues.iteration + 1;
    
    display_info_icm(options, optimValues);
    
    [stop, optimValues] = call_output_fnc_icm(x, options, optimValues, state);
    if (stop)
        state = 'interrupt';
        exitFlag = -1;
    else
        [stop, optimValues] = check_exit_conditions_icm(options, optimValues, current_score);
    end
    
end

%% Clean up, exit state
disp(optimValues.message);

state = 'done';
fval = optimValues.fval;

output = optimValues;
output.tlr = tlr;
output.tur = tur;

call_output_fnc_icm(x, options, optimValues, state);

% Remove the copies of x
x = x(1,:);

warning('on', 'MATLAB:scatteredInterpolant:InterpEmptyTri3DWarnId');

%% Auxiliary functions
    function [score] = calculate_score(i)
        
        score = data_term_score(i);
        
        n_i = getNeighborsIndices_icm(i, xyz);
        
        score = score + pairwise_term(i, n_i);
        
    end

    function [score] = data_term_score(i)
        
        score = zeros(1, size(x, 1));
        
        for k=1:numel(options.DataTermFcn)
            [data_score, optimValues] = options.DataTermFcn{k}(i, x,  ...
                options, optimValues, lb, ub);
            score = score + data_score * options.DataTermFactors(k);
        end
        
    end

    function score = pairwise_term(i, n_i)
        
        score = zeros(1, size(x, 1));
        
        for k=1:numel(options.PairWiseTermFcn)
            score = score + options.PairWiseTermFcn{k}(i, n_i, x, options, ...
                lb, ub) * options.PairWiseTermFactors(k);
        end
        
    end

    function [score] = calculate_score_all()
        
        score = ones(num_dim, 1);
        
        % If data term function is eval render, just render once as the
        % values are not changing
        if(isempty(options.DataTermFcn) || (numel(options.DataTermFcn) == 1 ...
                && ~isempty(strfind(func2str(options.DataTermFcn{1}), ...
                'eval_render_function_always_icm'))))
            
            [data_score, optimValues] = options.DataTermFcn{1}(1, x,  ...
                options, optimValues, lb, ub);
            
            score(:) = data_score * options.DataTermFactors(1);
            
            for k=1:num_dim
                n_i = getNeighborsIndices_icm(k, xyz);
                
                score(k) = score(k) + pairwise_term(k, n_i);
            end
        else
            for k=1:num_dim
                score(k) = calculate_score(k);
            end
        end
        
    end

end

