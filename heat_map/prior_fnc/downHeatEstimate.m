function prior_error = downHeatEstimate( xyz, v, volumeSize, temp_th, ...
    lb, ub)
%DOWNHEATESTIMATE Estimate of  heatMap downwards heat
%   PRIOR_ERROR = DOWNHEATESTIMATE( XYZ, V, VOLUMESIZE, TEMP_TH, LB, UB)
%   returns 0 in PRIOR_ERROR if the heat in the flame goes "down" for all
%   the voxels, 1 it goes "up", and intermediate values otherwise. The
%   heatmaps are defined by the common coordinates matrix 3xM  XYZ, the
%   value matrix NxM V, where the coordinates are in a volume given by
%   VOLUME_SIZE 1X3.
%
%   See also upHeatEstimate, upHeatEstimateLinear

num_vol = size(v, 1);

prior_error = zeros(1, num_vol);

% Get new set of indices without the lowest y, where each row corresponds
% to the voxel above the current one
xyz_no_first = xyz;
valid_idx = xyz(:, 2, :) ~= 1;

xyz_no_first(~valid_idx, :) = []; % Remove the top slice
xyz_no_first(:, 2) = xyz_no_first(:, 2) - 1; % Get the one below

bound_correction = 1 / (ub - lb - temp_th);
assert(~isnan(bound_correction) && ~isinf(bound_correction), 'Error in bounds');

for i=1:num_vol
    num_active = size(xyz_no_first, 1);
    assert(~isnan(num_active) && ~isinf(num_active), 'Error in num_active');
    
    if(num_active > 0)
        % Get a dense copy of V,
        V = zeros(volumeSize(1), volumeSize(2), volumeSize(3));
        vInd = sub2ind(volumeSize, xyz(:,1), xyz(:,2), xyz(:,3));
        V(vInd) = v(i,:);
        
        % Get the value of the voxel the is one voxel lower than the
        % current one, not counting the highest slice in the volume
        Vdown = arrayfun(@(i) V(xyz_no_first(i,1), xyz_no_first(i,2), ...
            xyz_no_first(i,3)), 1:num_active);
        
        % Compute the difference of each voxel with its down neighbour
        diff_down = Vdown - v(i,valid_idx);
        
        % If heat goes down and it is smaller than the threshold sum 1 for
        % each voxel
        down_th_smaller_idx = (diff_down > 0 & diff_down <= temp_th);
        prior_error(i) = sum(down_th_smaller_idx);
        
        % Remove the heat goes up and previous values
        diff_down(diff_down <= 0 | down_th_smaller_idx) = [];
        
        % Scale and offset the difference so that it is in the [0,1] range
        diff_down = (diff_down - temp_th) * bound_correction;
        
        % Add 1 if close to the threshold, 0 if far away, and linear
        % intermediate values for the differences in between them
        prior_error(i) = prior_error(i) + sum(1 - diff_down);
        
        % Divide by number of active pixels to not encourage sparseness and
        % negate to have a [0,1] prior were 0 is maximum up and 1 is
        % minimum
        prior_error(i) = 1 - prior_error(i) / num_active;
    end
end

assert_valid_range_in_0_1(prior_error);

end

