function [ hc_goal ] = getImgCombinedHistogram( img, img_mask, n_bins, ...
    edges, do_normalize)
%GETIMGCOMBINEDHISTOGRAM Get color estimate from image
%   [ HC_GOAL ] = GETIMGCOMBINEDHISTOGRAM( IMG, IMG_MASK, N_BINS) Color is
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

% Number of single bin combinations
bin_combinations = n_bins^size_3;

% Edges for the above bin combinations, since a X(i) falls in j if
% edges(j) <= X(i) < edges(j+1), we know that the combinations go from
% 1 to bin_combinations, get the edges so that all 1s fall in the first
% bin, all 2s in the second, and so on. Note that the last is
% edges(N) <= X(i) <= edges(N+1)
edges_all = (1:bin_combinations+1) - 0.5;

to_one_dim = [1, n_bins, n_bins^2];

% Multi goal optimization, compute the mean histogram of all the goal
% images

if(size(img_mask, 3) > 3)
    img_mask= img_mask(:,:,1);
end

% Vector for the bin number of each pixel, first dimension is RGB or
% other, and second is pixel number
num_valid_pixels = sum(img_mask(:));
hc_goal_rgb = zeros(size_3, num_valid_pixels);

% Do discretization (histogram) into n_bins
for j=1:size_3
    sub_img = img(:, :, j);
    hc_goal_rgb(j,:) = discretize(sub_img(img_mask), edges);
end

% Convert to single index, from 1 to bin_combinations
hc_goal_idx_single = to_one_dim * (hc_goal_rgb - 1) + 1;

assert(all(hc_goal_idx_single) >= 1, 'Invalid discretization');
assert(all(hc_goal_idx_single) <= n_bins^size_3, 'Invalid discretization');

% Do a histogram count using the combined bin indices
hc_goal = histcounts( hc_goal_idx_single, edges_all);

if do_normalize && num_valid_pixels > 0
    %assert(all(num_valid_pixels == sum(hc_goal')));
    hc_goal = hc_goal ./ num_valid_pixels;
end
end

