function smoothness = smoothnessEstimateGrad( xyz, v, volumeSize, lb, ub)
%SMOOTHNESSESTIMATEGRAD estimate heatMap smoothness
%   SMOOTH_V = SMOOTHNESSESTIMATEGRAD( XYZ, V, VOLUME_SIZE ) gives a
%   smoothness estimate in arbitrary units for the heatmaps defined by the
%   common coordinates matrix 3xM XYZ, the value matrix NxM V, where the
%   coordinates are in a volume given by VOLUME_SIZE 1X3. A small value in
%   SMOOTH_V means high smoothness and a large values indicate low
%   smoothness.

assert(all(volumeSize > 1), ['Volume size of each dimension must be ' ...
    'larger than one to be able to compute the gradients']);

num_vol = size(v, 1);

smoothness = zeros(1, num_vol);

% Normalization factor, inspired by Dobashi et. al. 2012
% Number of voxels * number of channels(x,y,z) * max gradient
% The objective is that for maximum smoothness; i.e. maximum gradient all
% the values would sum up to 1
total_voxels_inv = 1 / (3 * prod(volumeSize) * (ub - lb));

for i=1:num_vol
    num_active = size(v, 2);
    if(num_active > 0)
        % Get a dense copy of V, set the outside of the volume to be in the
        % lower bounds instead of zeros
        V = zeros(volumeSize(1), volumeSize(2), volumeSize(3)) + lb;
        vInd = sub2ind(volumeSize, xyz(:,1), xyz(:,2), xyz(:,3));
        V(vInd) = v(i,:);
        
        % Compute the gradient in each dimension
        [gradx, grady, gradz] = gradient(V);
        
        smoothness(i) = sum([abs(gradx(:))', abs(grady(:))', abs(gradz(:))']) ...
            * total_voxels_inv;
    end
end

end

