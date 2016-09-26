function [ score, optimValues ] = eval_render_function_half_ite_icm( i, x, ...
    options, optimValues, ~, ~, fun )
%EVAL_RENDER_FUNCTION_HALF_ITE_ICM Compute render function
if(options.DataTermEvalVMRand)
    if rand() < options.DataTermEvalVM
        score = fun(x);
        optimValues.funccount = optimValues.funccount + size(x, 1);
    else
        % Use only the other data and pair wise terms
        score = zeros(1, size(x, 1));
    end
else
    if mod(i + optimValues.iteration, options.DataTermEvalVM) == 0
        score = fun(x);
        optimValues.funccount = optimValues.funccount + size(x, 1);
    else
        % Use only the other data and pair wise terms
        score = zeros(1, size(x, 1));
    end
end
end

