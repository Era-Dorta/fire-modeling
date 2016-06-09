function abs_diff = diffToHeatMap( v, other_v, lb, ub)
%DIFFTOHEATMAP estimate heatMap difference
%   ABS_DIFF = DIFFTOHEATMAP( V, VOLUME_SIZE, OTHER_HM, LB, UB) gives a
%   difference estimate in (0,1) for the heatmaps defined by the value
%   matrix NxM V, LB and UB are the lower and upper bounds for the
%   temperatures. 0 means identical heatmaps and 1 completely different
%   ones.

num_vol = size(v, 1);

% Normalization factor, max voxel difference by two because it is L1 norm
total_voxels_inv = 1 / (2 * size(v, 2) * (ub - lb));

if ~isinf(total_voxels_inv)
    abs_diff = sum(abs(bsxfun(@minus, other_v', v'))) * total_voxels_inv;
else
    abs_diff = zeros(1, num_vol);
end

assert_valid_range_in_0_1(abs_diff);

end

