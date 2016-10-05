function [ score, optimValues ] = eval_render_function_always_icm_density( ~, x, ~, ...
    optimValues, ~, ~, fun )
%EVAL_RENDER_FUNCTION_ALWAYS_ICM Compute render function
score = fun(x, optimValues.do_temperature);
optimValues.funccount = optimValues.funccount + size(x, 1);
end

