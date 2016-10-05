function [optimValues] = cluster_reduce_ftol(~, options, optimValues, ~)
%CLUSTER_REDUCE_FTOL Cluster update function
%   [OPTIMVALUES] = CLUSTER_REDUCE_FTOL(X, OPTIONS, OPTIMVALUES, STATE)
persistent prev_fval

if optimValues.iteration == 0
    prev_fval = optimValues.fval;
    return;
end

if optimValues.ite_inc > 1 && ...
        (abs(optimValues.fval- prev_fval ) < options.FunctionTolerance)        
    optimValues.ite_inc = round(optimValues.ite_inc / 2);    
end
end

