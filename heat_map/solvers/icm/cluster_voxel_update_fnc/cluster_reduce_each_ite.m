function [optimValues] = cluster_reduce_each_ite(x, ~, optimValues, ~)
%CLUSTER_REDUCE_EACH_ITE Cluster update function
%   [OPTIMVALUES] = CLUSTER_REDUCE_EACH_ITE(X, OPTIONS, OPTIMVALUES, STATE)
if optimValues.iteration == 0
    return;
end
if optimValues.num_clusters < numel(x)
    optimValues.num_clusters = min(optimValues.num_clusters * 2, numel(x));
end
end

