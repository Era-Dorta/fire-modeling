function [ score, optimValues ] = eval_render_function_always_icm( ~, x,  options, ...
    optimValues, ~, ~, fun )
%EVAL_RENDER_FUNCTION_ALWAYS_ICM Compute render function
score = fun(x);
optimValues.funcCount = optimValues.funcCount + options.TemperatureNSamples;
end

