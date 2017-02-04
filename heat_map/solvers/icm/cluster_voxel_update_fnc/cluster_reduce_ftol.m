function [optimValues] = cluster_reduce_ftol(~, options, optimValues, ~)
%CLUSTER_REDUCE_FTOL Cluster update function
%   [OPTIMVALUES] = CLUSTER_REDUCE_FTOL(X, OPTIONS, OPTIMVALUES, STATE)
persistent prev_fval

if optimValues.iteration == 0
    prev_fval = optimValues.fval;
    return;
end

if optimValues.num_clusters < numel(x) && ...
        (abs(optimValues.fval- prev_fval ) < options.FunctionTolerance)        
    optimValues.num_clusters = min(optimValues.num_clusters * 2, numel(x));
end
end

