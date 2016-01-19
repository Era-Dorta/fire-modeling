function smoothness = smoothnessEstimate( xyz, v, volumeSize )
%SMOOTHNESS_ESTIMATE estimate heatMap smoothness
%   SMOOTH_V = SMOOTHNESS_ESTIMATE( XYZ, V, VOLUME_SIZE ) gives a
%   smoothness estimate in arbitrary units for the heatmaps defined by the
%   common coordinates matrix 3xM XYZ, the value matrix NxM V, where the
%   coordinates are in a volume given by VOLUME_SIZE 1X3. A small value in
%   SMOOTH_V means high smoothness and a large values indicate low
%   smoothness.

num_vol = size(v, 1);

smoothness = zeros(1, num_vol);

% Add one to each index to account for the front padding
xyz = xyz + 1;
volumeSize = volumeSize + 2;

for i=1:num_vol
    num_active = size(v, 2);
    if(num_active > 0)
        % Get a dense copy of V,
        V = zeros(volumeSize(1), volumeSize(2), volumeSize(3));
        vInd = sub2ind(volumeSize, xyz(:,1), xyz(:,2), xyz(:,3));
        V(vInd) = v(i,:);
        
        % Compute the mean for each valid voxel using its Moore neighbor
        % voxels, one voxel on each direction including the diagonals
        Vmean = arrayfun(@(i) mean(reshape(V(xyz(i,1)-1:xyz(i,1)+1, ...
            xyz(i,2)-1:xyz(i,2)+1, xyz(i,3)-1:xyz(i,3)+1), 1, 27)), 1:num_active);
        
        % Compute the mean square error between both volumes
        error = Vmean - v(i,:);
        smoothness(i) = sum(sum(error .* error)) / num_active;
    end
end

end

