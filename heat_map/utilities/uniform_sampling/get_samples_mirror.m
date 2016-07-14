function [ heat_map_v, bin_norm ] = get_samples_mirror( opts )
%GET_SAMPLES_MIRROR Get random samples using the mirror method

% For each sample we need two heat maps
heat_map_v = cell(opts.samples_n_bins, 1);

bin_norm = zeros(opts.samples_n_bins, 1);

% Copy data to have more efficient parfor evaluation
num_samples = opts.num_samples;
hm_count = opts.hm_count;
lb = opts.LB;
ub = opts.UB;

heat_map_v(:) = {zeros(num_samples, hm_count)};
diff_b_step = ((ub - lb) / 2) / opts.samples_n_bins;

% j inverse because the nlb and nub are computed in the inverse order
jr = opts.samples_n_bins;

% for as it is quite computationally intensive
for j=1:opts.samples_n_bins
    % Get hypercube inner and outher bounds
    nlb(1) = lb + diff_b_step * (j - 1);
    nub(1) = ub - diff_b_step * j;
    nlb(2) = lb + diff_b_step * j;
    nub(2) = ub - diff_b_step * (j - 1);
    
    for i=2:2:num_samples
        
        % Choose a voxel randomly
        idx = randi(hm_count, 1, 1);
        
        % Generate random point and its mirror
        heat_map_v{jr}(i-1,:) = rand(1, hm_count);
        heat_map_v{jr}(i,:) = 1 - heat_map_v{jr}(i-1,:);
        
        s_val1 = heat_map_v{jr}(i-1,idx);
        
        % Put all the values inside the current hypercube
        heat_map_v{jr}(i-1,:) = fitToRange(heat_map_v{jr}(i-1,:), 0, 1, nlb(1), nub(2));
        heat_map_v{jr}(i,:) = fitToRange(heat_map_v{jr}(i,:), 0, 1, nlb(1), nub(2));
        
        % One voxel value must be in the band of the edge of the
        % hypercube so that the inside is not sampled, this guaranties
        % a minimum norm distance of abs(nlb(1) - nlb(2))
        if rand() > 0.5
            heat_map_v{jr}(i-1,idx) = fitToRange(s_val1, 0, 1, nlb(1), nlb(2));
            heat_map_v{jr}(i,idx) = fitToRange(1 - s_val1, 0, 1, nub(1), nub(2));
        else
            heat_map_v{jr}(i-1,idx) = fitToRange(s_val1, 0, 1, nub(1), nub(2));
            heat_map_v{jr}(i,idx) = fitToRange(1 - s_val1, 0, 1, nlb(1), nlb(2));
        end
        
        bin_norm(jr) = bin_norm(jr) + norm(heat_map_v{jr}(i-1,:) - heat_map_v{jr}(i,:));
    end
    bin_norm(jr) = bin_norm(jr)/(num_samples/2);
    jr = jr - 1;
end

end

