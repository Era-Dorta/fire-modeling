function [ x, fval, exitFlag, output ] = icm ( fun, x0, lb, ub, options)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
exitFlag = 0;
num_dim = numel(x0);

cur_score = inf(num_dim, 1);
t = linspace(lb(1), ub(1), options.TemperatureNSamples);
x = x0;

optimValues.fval = inf;
optimValues.iteration = 0;
optimValues.funcCount = 0;

state = 'init';
call_output_fnc();

state = 'iter';

while(true)
    current_score = 0;
    for i=1:num_dim
        current_score = current_score + cur_score(i);
    end
    
    for i=1:num_dim
        
        min_score = cur_score(i);
        cur_temp = x(i);
        for j=1:options.TemperatureNSamples
            
            if (t(j) == cur_temp)
                continue;
            end
            % bool do_replacement = false;
            x(i) = t(j);
            new_score = calculate_score(i, x);
            if (new_score < min_score)
                
                cur_temp = t(j);
                min_score = new_score;
                
            end
            
        end
        x(i) = cur_temp;
        cur_score(i) = min_score;
    end
    
    
    new_score = 0;
    for i=1:num_dim
        new_score = new_score + cur_score(i);
    end
    
    if(call_output_fnc())
        state = 'interrupt';
        exitFlag = -1;
        break;
    end
    
    if (abs(new_score-current_score ) < options.FunctionTolerance || ...
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

    function [stop] = call_output_fnc()
        stop = false;
        for k=1:numel(options.OutputFcn)
            if(options.OutputFcn{k}(x, optimValues, state))
                stop = true;
            end
        end
    end

    function [score] = calculate_score(i, x)
        
        score = data_term_score(i);
        
        if(false)
            neighbors = getNeighbors(i);
            
            for k=1:numel(neighbors)
                score =  score + pairwise_term(i, n, x);
            end
        end
    end

    function [score] = data_term_score(i)
        
        score = fun(x);
        optimValues.funcCount = optimValues.funcCount + 1;
        
    end

end

