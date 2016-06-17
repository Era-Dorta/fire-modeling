function abs_diff = diffToHeatMapWithNeigh(v, v1, volumeSize, xyz, lb, ub)
%DIFFTOHEATMAPWITHNEIGH estimate heatMap difference
%   ABS_DIFF = DIFFTOHEATMAPWITHNEIGH(V, V1, VOLUMESIZE, XYZ, LB, UB)
%   gives a  difference estimate in (0,1) for the heatmaps defined by the
%   value matrix NxM V, LB and UB are the lower and upper bounds for the
%   temperatures. The difference is defined in terms of voxel neighbours,
%   i.e. if a heatmap is a scaled version of the other the distance would
%   zero.

persistent xyz_r mean_diff1 V1

num_vol = size(v, 1);

abs_diff = zeros(1, num_vol);

neigh_offset = [1, 0, 0; -1, 0, 0; 0, 1, 0; 0, -1, 0; 0, 0, 1; 0, 0, -1];

if isempty(xyz_r)
    % Get new set of indices without the edges
    xyz_r = xyz;
    
    valid_idx = zeros(size(xyz,1), 1);
    for i=1:3
        valid_idx = (xyz(:, i, :) == 1 )| valid_idx;
        valid_idx = (xyz(:, i, :) == volumeSize(i)) | valid_idx;
    end
    valid_idx = ~valid_idx;
    
    xyz_r(~valid_idx, :) = []; % Remove the edges
    
    V1 = zeros(volumeSize(1), volumeSize(2), volumeSize(3));
    vInd = sub2ind(volumeSize, xyz(:,1), xyz(:,2), xyz(:,3));
    V1(vInd) = v1';
    
    num_active = size(xyz_r, 1);
    mean_diff1 = zeros(size(xyz_r, 1), 1);
    
    for j=1:num_active
        % Three dimensional neighbour indices
        neigh_idx = bsxfun(@plus, neigh_offset, xyz_r(j,:));
        
        % Linear neighbour indices
        neigh_idx = sub2ind(volumeSize, neigh_idx(:,1), neigh_idx(:,2), ...
            neigh_idx(:,3));
        
        % Mean of  the differences of current voxel with neighbours
        mean_diff1(j) = mean(abs(V1(neigh_idx) - V1(xyz_r(j,1), ...
            xyz_r(j,2), xyz_r(j,3))));
    end
end

num_active = size(xyz_r, 1);
assert(~isnan(num_active) && ~isinf(num_active), 'Error in num_active');

if(num_active == 0)
    return;
end

% Normalization factor, max voxel difference by number of evaluated voxels
correction = 1 / (num_active * (ub - lb));
assert(~isnan(correction) && ~isinf(correction), 'Error in bounds');

for i=1:num_vol
    
    % Get a dense copy of V,
    V = zeros(volumeSize(1), volumeSize(2), volumeSize(3));
    vInd = sub2ind(volumeSize, xyz(:,1), xyz(:,2), xyz(:,3));
    V(vInd) = v(i,:);
    
    for j=1:num_active
        % Three dimensional neighbour indices
        neigh_idx = bsxfun(@plus, neigh_offset, xyz_r(j,:));
        
        % Linear neighbour indices
        neigh_idx = sub2ind(volumeSize, neigh_idx(:,1), neigh_idx(:,2), ...
            neigh_idx(:,3));
        
        % Mean of  the differences of current voxel with neighbours
        mean_diff0 = mean(abs(V(neigh_idx) - V(xyz_r(j,1), xyz_r(j,2), ...
            xyz_r(j,3))));
        
        % Difference of the mean of the differences
        abs_diff(i) = abs_diff(i) + abs(mean_diff0 - mean_diff1(j));
    end
    
    abs_diff(i) = abs_diff(i) * correction;
end

assert_valid_range_in_0_1(abs_diff);

end