function [stop, optimValues] = check_exit_conditions_icm(options, optimValues, current_score)
stop = false;
if (abs(optimValues.fval-current_score ) < options.FunctionTolerance)
    optimValues.message = 'Change in fval smaller than FunctionTolerance';
    stop = true;
    return;
end
if (optimValues.iteration > options.MaxIterations)
    optimValues.message = 'MaxIterations reached';
    stop = true;
    return;
end
if (optimValues.funcCount > options.MaxFunctionEvaluations)
    optimValues.message = 'MaxFunctionEvaluations reached';
    stop = true;
    return;
end
end