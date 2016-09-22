function [ score, optimValues ] = eval_render_function_half_ite_icm( i, x, ~, ...
    optimValues, ~, ~, fun )
%EVAL_RENDER_FUNCTION_HALF_ITE_ICM Compute render function
if mod(i + optimValues.iteration, 10) == 0
    score = fun(x);
    optimValues.funccount = optimValues.funccount + size(x, 1);
else
    % No weight on this iteration use only the other data and pair wise
    % terms
    score = zeros(1, size(x, 1));
end
end

