function [clusters_idx, optimValues] = sequential_cluster(x, ~, options, optimValues, state)
%SEQUENTIAL_CLUSTER
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

% Divide the data as evenly as possible in sequential order
% Example: num_dim = 10,
% num_clusters = 2 -> clusters_idx = {[1, 2, 3, 4, 5],[6, 7, 8, 9, 10]}
% num_clusters = 6 -> clusters_idx = {[1,2],3,[4,5],[6,7],8,[9,10]}
    function compute_clusters()
        num_dim = numel(x);
        ite_inc = num_dim / optimValues.num_clusters;
        idx = round(1:ite_inc:num_dim);
        clusters_idx = cell(1, optimValues.num_clusters);
        for i = 1:numel(idx)-1
            clusters_idx{i} = (idx(i):idx(i+1)-1);
        end
        clusters_idx{end} = (idx(end):num_dim);
    end

end

