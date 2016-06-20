function [ out_hm ] = apply_gaussian_blur( in_hm, bg, g_size )
%APPLY_GAUSSIAN_BLUR Apply Gaussia blur to heatmap
%   [ OUT_HM ] = APPLY_GAUSSIAN_BLUR( IN_HM ) Blur the heatmap
%   IN_HM and get the result in OUT_HM.
%
%   [ OUT_HM ] = APPLY_GAUSSIAN_BLUR( IN_HM, BG ) The background values
%   for the sparse values in the heat map can be specified with LB. Default
%   is 0.
%
%   [ OUT_HM ] = APPLY_GAUSSIAN_BLUR( IN_HM, BG, G_SIZE ) The radius of
%   the gaussian filter can be set with G_SIZE, note that actual size is
%   2 * G_SIZE + 1. Default is 1.

if nargin == 1
    % BAckground values
    bg = 0;
end

if nargin <= 2
    % g_size of 1 generates a 3x3 filter
    g_size = 1;
end

h = fspecial('disk', g_size);

% Replicate the filter so it is three-dimensional, divide by three so that
% the total energy does not increase after applying the filter
h = repmat(h, 1, 1, 3) / 3;

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

