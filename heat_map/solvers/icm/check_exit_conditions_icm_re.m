function [stop, optimValues] = check_exit_conditions_icm_re(options, optimValues, current_score)
stop = false;
if (abs(optimValues.fval-current_score ) < options.FunctionTolerance)
    if floor(optimValues.ite_inc / 2) >= 1
        optimValues.ite_inc = round(optimValues.ite_inc / 2);
        disp(['Change in fval smaller than FunctionTolerance, new ' ...
            ' iteration increment ' num2str(optimValues.ite_inc)]);
    else
        optimValues.procedure = 'Change in fval smaller than FunctionTolerance';
        stop = true;
    end    
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