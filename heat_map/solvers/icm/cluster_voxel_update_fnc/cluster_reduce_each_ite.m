function [optimValues] = cluster_reduce_each_ite(~, ~, optimValues, ~)
%CLUSTER_REDUCE_EACH_ITE Cluster update function
%   [OPTIMVALUES] = CLUSTER_REDUCE_EACH_ITE(X, OPTIONS, OPTIMVALUES, STATE)
if optimValues.iteration == 0
    return;
end
if optimValues.ite_inc > 1
    optimValues.ite_inc = round(optimValues.ite_inc / 2);
end
end

