function [clusters_idx, optimValues] = k_means_cluster(x, xyz, options, optimValues, state)
%K_MEANS_CLUSTER
persistent prev_clusters_idx

if optimValues.iteration == 0
    optimValues = options.ClusterUpdateFnc(x, options, optimValues, state);
    compute_clusters();
    prev_clusters_idx = clusters_idx;
    return;
end

num_clusters = optimValues.num_clusters;
optimValues = options.ClusterUpdateFnc(x, options, optimValues, state);

if num_clusters ~= optimValues.num_clusters
    compute_clusters();
    prev_clusters_idx = clusters_idx;
else
    clusters_idx = prev_clusters_idx;
end

    function compute_clusters()
        clusters_idx = cell(1, optimValues.num_clusters);
        idx = kmeans(xyz, optimValues.num_clusters);
        for i=1:optimValues.num_clusters
            clusters_idx{i} = find(idx == i);
        end
    end

end

