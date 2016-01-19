function smoothness = smoothnessEstimateGrad( xyz, v, volumeSize )
%SMOOTHNESSESTIMATEGRAD estimate heatMap smoothness
%   SMOOTH_V = SMOOTHNESSESTIMATEGRAD( XYZ, V, VOLUME_SIZE ) gives a
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
        
        % Compute the gradient in each dimension
        [gradx, grady, gradz] = gradient(V);
        
        smoothness(i) = sum([norm(gradx(:)), norm(grady(:)), norm(gradz(:))]);
    end
end

end

