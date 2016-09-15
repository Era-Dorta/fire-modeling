function [ x, fval, exitFlag, output ] = icm ( fun, x0, lb, ub, options)
%ICM Iterative Conditional Modes parallel solver

exitFlag = 0;
num_dim = numel(x0);

cur_score = inf(num_dim, 1);
t = linspace(lb(1), ub(1), options.TemperatureNSamples);

% Replicate x to be able to evaluate in parallel
x = repmat(x0, options.TemperatureNSamples, 1);

optimValues.fval = inf;
optimValues.iteration = 0;
optimValues.funcCount = 0;

state = 'init';
call_output_fnc();

state = 'iter';

while(true)
    
    current_score = sum(cur_score);
    
    % Iterate for each voxel
    for i=1:num_dim
        
        % Get score for the current voxel
        min_score = cur_score(i);
        cur_temp = x(1, i);
        
        % Assign a different temperature to each copy of x
        x(:, i) = t;
        
        % Compute all the scores
        new_score = calculate_score(i, x);
        
        % Get the min
        [new_score, j] = min(new_score);
        
        % Update on improvement
        if (new_score < min_score)
            cur_temp = t(j);
            min_score = new_score;
        end
        
        % Set the voxel to have the best temperature so far
        x(:, i) = cur_temp;
        cur_score(i) = min_score;
        
    end
    
    optimValues.fval = sum(cur_score);
    
    if(call_output_fnc())
        state = 'interrupt';
        exitFlag = -1;
        break;
    end
    
    if (abs(optimValues.fval-current_score ) < options.FunctionTolerance || ...
            optimValues.iteration > options.MaxIterations || ...
            optimValues.funcCount > options.MaxFunctionEvaluations)
        break;
    end
    
    optimValues.iteration = optimValues.iteration + 1;
end

state = 'done';
fval = optimValues.fval;

output = optimValues;

call_output_fnc();

x = x(1,:);

    function [stop] = call_output_fnc()
        stop = false;
        for k=1:numel(options.OutputFcn)
            if(options.OutputFcn{k}(x(1,:), optimValues, state))
                stop = true;
            end
        end
    end

    function [score] = calculate_score(i, x)
        
        score = data_term_score(i, x);
        
        if(false)
            neighbors = getNeighbors(i);
            
            for k=1:numel(neighbors)
                score =  score + pairwise_term(i, n, x);
            end
        end
    end

    function [score] = data_term_score(i, x)
        
        score = fun(x);
        optimValues.funcCount = optimValues.funcCount + options.TemperatureNSamples;
        
    end

end

