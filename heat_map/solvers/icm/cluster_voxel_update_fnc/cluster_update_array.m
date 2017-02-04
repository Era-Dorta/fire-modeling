function [optimValues] = cluster_update_array(x, options, optimValues, ~)
%CLUSTER_UPDATE_ARRAY
persistent cluster_n_array

if optimValues.iteration == 0
    % Size of -1 means do not cluster, so change the values to the input
    % size
    cluster_n_array = options.cluster_n_array;
    cluster_n_array(cluster_n_array == -1) = numel(x);
    return;
end

if optimValues.iteration <= numel(cluster_n_array) && ...
        cluster_n_array(optimValues.iteration) <= numel(x)
    optimValues.num_clusters = cluster_n_array(optimValues.iteration);
end

end
