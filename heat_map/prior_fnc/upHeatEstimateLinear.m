function upHeatV = upHeatEstimateLinear( xyz, v, volumeSize, temp_th, lb, ub)
%UPHEATESTIMATELINEAR estimate heatMap upwards heat
%   UP_HEAT_V = UPHEATESTIMATELINEAR( XYZ, V, VOLUME_SIZE ) returns 0 in
%   UP_HEAT_V if the heat in the flame goes "up" for all the voxels, 1 it
%   goes "down", and intermediate values otherwise. The heatmaps are
%   defined by the common coordinates matrix 3xM  XYZ, the value matrix NxM
%   V, where the coordinates are in a volume given by VOLUME_SIZE 1X3.
%
%   See also upHeatEstimate

num_vol = size(v, 1);

upHeatV = zeros(1, num_vol);

% Get new set of indices without the highest y, where each row corresponds
% to the voxel above the current one
xyz_no_last = xyz;
valid_idx = xyz(:, 2, :) ~= volumeSize(2);

xyz_no_last(~valid_idx, :) = []; % Remove the top slice
xyz_no_last(:, 2) = xyz_no_last(:, 2) + 1; % Get the one above

bound_correction = 1 / (ub - lb - temp_th);
assert(~isnan(bound_correction) && ~isinf(bound_correction), 'Error in bounds');

for i=1:num_vol
    num_active = size(xyz_no_last, 1);
    assert(~isnan(num_active) && ~isinf(num_active), 'Error in num_active');
    
    if(num_active > 0)
        % Get a dense copy of V,
        V = zeros(volumeSize(1), volumeSize(2), volumeSize(3));
        vInd = sub2ind(volumeSize, xyz(:,1), xyz(:,2), xyz(:,3));
        V(vInd) = v(i,:);
        
        % Get the value of the voxel the is one voxel higher than the
        % current one, not counting the highest slice in the volume
        Vup = arrayfun(@(i) V(xyz_no_last(i,1), xyz_no_last(i,2), ...
            xyz_no_last(i,3)), 1:num_active);
        
        % Compute the difference of each voxel with its up neighbour
        diff_up = Vup - v(i,valid_idx);
        
        % If heat goes up and it is smaller than the threshold sum 1 for
        % each voxel
        up_th_smaller_idx = (diff_up > 0 & diff_up <= temp_th);
        upHeatV(i) = sum(up_th_smaller_idx);
        
        % Remove the heat goes down and previous values
        diff_up(diff_up <= 0 | up_th_smaller_idx) = [];
        
        % Scale and offset the difference so that it is in the [0,1] range
        diff_up = (diff_up - temp_th) * bound_correction;
        
        % Add 1 if close to the threshold, 0 if far away, and linear
        % intermediate values for the differences in between them
        upHeatV(i) = upHeatV(i) + sum(1 - diff_up);
        
        % Divide by number of active pixels to not encourage sparseness and
        % negate to have a [0,1] prior were 0 is maximum up and 1 is
        % minimum
        upHeatV(i) = 1 - upHeatV(i) / num_active;
    end
end

assert_valid_range_in_0_1(upHeatV);

end

