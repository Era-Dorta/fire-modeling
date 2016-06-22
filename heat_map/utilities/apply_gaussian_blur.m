function [ out_hm ] = apply_gaussian_blur( in_hm, bg, g_size, g_sigma )
%APPLY_GAUSSIAN_BLUR Apply Gaussia blur to heatmap
%   [ OUT_HM ] = APPLY_GAUSSIAN_BLUR( IN_HM ) Blur the heatmap
%   IN_HM and get the result in OUT_HM.
%
%   [ OUT_HM ] = APPLY_GAUSSIAN_BLUR( IN_HM, BG ) The background values
%   for the sparse values in the heat map can be specified with LB. Default
%   is 0.
%
%   [ OUT_HM ] = APPLY_GAUSSIAN_BLUR( IN_HM, BG, G_SIZE ) The radius of
%   the gaussian filter can be set with G_SIZE. Default is 3.
%
%   [ OUT_HM ] = APPLY_GAUSSIAN_BLUR( IN_HM, BG, G_SIZE, G_SIGMA ) The
%   amount of blurring can be controled with G_SIGMA. Default is 0.5, which
%   approximately takes 50% from the original voxel value and 50% from its 
%   neighbours.

if nargin == 1
    % Background values
    bg = 0;
end

if nargin <= 2
    % g_size of 3 generates a 3x3 filter
    g_size = 3;
end

if nargin <= 3
    % g_sigma of 0.5, give the centre voxel a weight of 0.4874
    g_sigma = 0.5;
end

h = fspecial('gaussian', g_size, g_sigma);

% Replicate the filter so it is three-dimensional,
% the total energy does not increase after applying the filter
h = repmat(h, 1, 1, 3);

% Make the frontal and back centre have the same values as the voxels with
% the same distance in the centre of the filter
h(:,:,[1,3]) = (h(:,:,[1,3]) / h(2,2,1) ) * h(2, 1, 2);

% Make the sum equal to 1 for the total energy to remain the same
h = h / sum(h(:));

out_hm = in_hm;

% Replicate the data in dense format
V = zeros(in_hm.size(1), in_hm.size(2), in_hm.size(3)) + bg;
vInd = sub2ind(in_hm.size, in_hm.xyz(:,1), in_hm.xyz(:,2), in_hm.xyz(:,3));
V(vInd) = in_hm.v;

% Apply the filter
V = imfilter(V, h);

% Copy the data with the sparse indices
out_hm.v = V(vInd);

end

