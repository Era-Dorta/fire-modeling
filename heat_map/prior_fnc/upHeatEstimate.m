function upHeatV = upHeatEstimate( xyz, v, volumeSize )
%UPHEATESTIMATE estimate heatMap upwards heat
%   UP_HEAT_V = UPHEATESTIMATE( XYZ, V, VOLUME_SIZE ) returns 1 in
%   UP_HEAT_V if the heat in the flame goes "up" for all the voxels, 0 it
%   goes "down", and intermediate values otherwise. The heatmaps are
%   defined by the common coordinates matrix 3xM  XYZ, the value matrix NxM
%   V, where the coordinates are in a volume given by VOLUME_SIZE 1X3.

num_vol = size(v, 1);

upHeatV = zeros(1, num_vol);

% Get new set of indices without the highest y
xyz_no_last = xyz;
valid_idx = xyz(:, 2, :) ~= volumeSize(2);
xyz_no_last(~valid_idx, :) = [];

for i=1:num_vol
    num_active = size(xyz_no_last, 1);
    if(num_active > 0)
        % Get a dense copy of V,
        V = zeros(volumeSize(1), volumeSize(2), volumeSize(3));
        vInd = sub2ind(volumeSize, xyz(:,1), xyz(:,2), xyz(:,3));
        V(vInd) = v(i,:);
        
        % Get the value of the voxel the is one voxel higher than the
        % current one, not counting the highest slice in the volume
        Vup = arrayfun(@(i) V(xyz_no_last(i,1), xyz_no_last(i,2)+1, ...
            xyz_no_last(i,3)), 1:num_active);
        
        % Each voxel that satisfies the rule increases the upHeatV value,
        % divide by the number of active voxels, otherwise we would also be
        % encouraging sparseness
        upHeatV(i) = sum(Vup >= v(i,valid_idx)) / num_active;
    end
end

end

