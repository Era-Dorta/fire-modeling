function [ hc_goal ] = getImgRGBHistogram( img, img_mask, n_bins, edges, ...
    do_normalize)
%GETIMGRGBHISTOGRAM Get color estimate from image
%   [ HC_GOAL ] = GETIMGRGBHISTOGRAM( IMG, IMG_MASK, N_BINS) Color is
%   computed using the the combined RGB histogram of an image. IMG is a
%   color image MxNxP, IMG_MASK is a logical mask image MxN, and N_BINS is
%   the number of bins for the histogram. Size of HC_GOAL is 1xN_BINS^P.
%
%   See also getColorFromHistoIndex, getImgMeanColor, getImgStdColor

%% Compute histogram of the goal image
if nargin == 4
    do_normalize = false;
end

size_3 = size(img, 3);
hc_goal = zeros(size_3, n_bins);

for i=1:size_3
    sub_img = img(:, :, i);
    hc_goal(i,:) = histcounts( sub_img(img_mask), edges);
end

% Normalize by the number of pixels
num_pixels = sum(img_mask(:));
if do_normalize && num_pixels > 0
    %assert(all(num_pixels == sum(hc_goal)));
    hc_goal = hc_goal ./ num_pixels;
end
end
