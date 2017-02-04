function [optimValues] = cluster_reduce_nth_ite(~, options, optimValues, ~)
%CLUSTER_REDUCE_NTH_ITE Cluster update function
%   [OPTIMVALUES] = CLUSTER_REDUCE_NTH_ITE(X, OPTIONS, OPTIMVALUES, STATE)
if optimValues.iteration == 0
    return;
end
if optimValues.num_clusters < numel(x) && ...
        mod(optimValues.iteration, options.cluster_n_reduce) == 0
    optimValues.num_clusters = min(optimValues.num_clusters * 2, numel(x));
end
end

