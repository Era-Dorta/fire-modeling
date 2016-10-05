function [optimValues] = cluster_reduce_nth_ite(~, options, optimValues, ~)
%CLUSTER_REDUCE_NTH_ITE Cluster update function
%   [OPTIMVALUES] = CLUSTER_REDUCE_NTH_ITE(X, OPTIONS, OPTIMVALUES, STATE)
if optimValues.iteration == 0
    return;
end
if optimValues.ite_inc > 1 && ...
        mod(optimValues.iteration, options.cluster_n_reduce) == 0
    optimValues.ite_inc = round(optimValues.ite_inc / 2);    
end
end

