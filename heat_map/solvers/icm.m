function [ x, fval, exitFlag, output ] = icm ( fun, x0, xyz, lb, ub, options)
%ICM Iterative Conditional Modes parallel solver

exitFlag = 0;
num_dim = numel(x0);

cur_score = ones(num_dim, 1);

% Replicate x to be able to evaluate in parallel
x = repmat(x0, options.TemperatureNSamples, 1);

% Temperature range, it will be gradually deacreased for each voxel
tlr = lb;
tur = ub;

% Copy the data using an interpolant for easy access using the xyz coords
x_interp = scatteredInterpolant(xyz(:, 1), xyz(:, 2), xyz(:, 3), ...
    x0', 'nearest', 'none' );
warning('off', 'MATLAB:scatteredInterpolant:InterpEmptyTri3DWarnId');

optimValues.fval = 1;
optimValues.iteration = 0;
optimValues.funcCount = 0;
optimValues.message = 'Initial message';

if(options.TemperatureNSamples < 2)
    exitFlag = -1;
    optimValues.message = 'TemperatureNSamples must be >= 2';
    disp(optimValues.message);
    return;
end

state = 'init';
[~, optimValues] = call_output_fnc_icm(x, options, optimValues, state);

state = 'iter';

while(true)
    
    current_score = mean(cur_score);
    
    % Iterate for each voxel
    for i=1:num_dim
        
        % Get temperature for the current voxel
        cur_temp = x(1, i);
        
        % Assign a different temperature to each copy of x
        t = options.CreateSamplesFcn(i, options, tlr, tur);
        x(:, i) = t;
        
        % Compute all the scores
        new_score = calculate_score(i, x);
        
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
    
    display_info_icm(options, optimValues);
    
    [stop, optimValues] = call_output_fnc_icm(x, options, optimValues, state);
    if (stop)
        state = 'interrupt';
        exitFlag = -1;
        break;
    end
    
    [stop, optimValues] = check_exit_conditions_icm(options, optimValues, current_score);
    if (stop)
        break;
    end
    
    optimValues.iteration = optimValues.iteration + 1;
end

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

    function [score] = calculate_score(i, x)
        
        score = data_term_score(i, x) * 0.8;
        
        n_i = getNeighborsIndices_icm(i, xyz);
        
        score = score + pairwise_term(i, n_i, x, options, lb, ub) * 0.2;
    end

    function [score] = data_term_score(i, x)
        
        if true %mod(optimValues.iteration, 2) == 0
            score = fun(x);
            optimValues.funcCount = optimValues.funcCount + options.TemperatureNSamples;
        else
            score = ones(1, options.TemperatureNSamples);
        end
        
    end

    function score = pairwise_term(i, n_i, x, options, lb, ub)
        
        score = options.PairWiseTermFcn{1}(i, n_i, x, options, lb, ub);
        
        for k=2:numel(options.PairWiseTermFcn)
            score = score + options.PairWiseTermFcn{k}(i, n_i, x, options, lb, ub);
        end

    end

end

