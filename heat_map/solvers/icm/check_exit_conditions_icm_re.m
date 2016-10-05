function [stop, optimValues] = check_exit_conditions_icm_re(options, optimValues, current_score)
stop = false;
if (abs(optimValues.fval-current_score ) < options.FunctionTolerance)
    optimValues.procedure = 'Change in fval smaller than FunctionTolerance';
    stop = true;
    return;
end
if (optimValues.iteration > options.MaxIterations)
    optimValues.procedure = 'MaxIterations reached';
    stop = true;
    return;
end
if (optimValues.funccount > options.MaxFunctionEvaluations)
    optimValues.procedure = 'MaxFunctionEvaluations reached';
    stop = true;
    return;
end
end