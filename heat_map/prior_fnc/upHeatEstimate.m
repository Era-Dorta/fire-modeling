function upHeatV = upHeatEstimate( xyz, v, volumeSize )
%UPHEATESTIMATE estimate heatMap upwards heat
%   UP_HEAT_V = UPHEATESTIMATE( XYZ, V, VOLUME_SIZE ) returns large values
%   in UP_HEAT_V if the heat in the flame goes "up" and lower values
%   otherwise. The estimate is in arbitrary units for the heatmaps defined
%   by the common coordinates matrix 3xM XYZ, the value matrix NxM V, where
%   the coordinates are in a volume given by VOLUME_SIZE 1X3.

num_vol = size(v, 1);

upHeatV = zeros(1, num_vol);

% Add padding in the height dimension, as we are going to be comparing with
% the upper voxels
volumeSize(2) = volumeSize(2) + 1;

for i=1:num_vol
    num_active = size(v, 2);
    if(num_active > 0)
        % Get a dense copy of V,
        V = zeros(volumeSize(1), volumeSize(2), volumeSize(3));
        vInd = sub2ind(volumeSize, xyz(:,1), xyz(:,2), xyz(:,3));
        V(vInd) = v(i,:);
        
        % Get the value of the voxel the is one voxel higher than the current
        % one
        Vup = arrayfun(@(i) V(xyz(i,1), xyz(i,2)+1, xyz(i,3)), 1:num_active);
        
        % Each voxel that satisfies the rule increases the upHeatV value,
        % divide by the number of active voxels, otherwise we would also be
        % encouraging sparseness
        upHeatV(i) = sum(Vup >= v(i,:)) / num_active;
    end
end

end

