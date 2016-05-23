function [ hc_goal ] = getImgsCombinedHistogram( img, img_mask, n_bins)
%GETIMGMODECOLOR Get color estimate from image
%   [ OUT_RGB ] = GETIMGMODECOLOR( IMG, IMG_MASK, N_BINS) Color is
%   computed using the mode. IMG is a cell of color images, IMG_MASK a cell
%   of logical mask images, and N_BINS is the number of bins for the
%   histogram used to compute de mode. The image/s mode color is given in
%   OUT_RGB.
%
%   See also getImgMeanColor, getImgStdColor

%% Compute histogram of the goal image

size_3 = size(img{1}, 3);

% Create n_bins bins for the histogram
edges = linspace(0, 255, n_bins+1);

% Number of single bin combinations
bin_combinations = n_bins^size_3;

% Edges for the above bin combinations, since a X(i) falls in j if
% edges(j) <= X(i) < edges(j+1), we know that the combinations go from
% 1 to bin_combinations, get the edges so that all 1s fall in the first
% bin, all 2s in the second, and so on. Note that the last is
% edges(N) <= X(i) <= edges(N+1)
edges_all = (1:bin_combinations+1) - 0.5;

hc_goal = zeros(1, bin_combinations);

to_one_dim = [1, n_bins, n_bins^2];

% Multi goal optimization, compute the mean histogram of all the goal
% images
num_goal = numel(img);
for i=1:num_goal
    if(size(img_mask{i}, 3) > 3)
        img_mask{i}= img_mask{i}(:,:,1);
    end
    
    % Vector for the bin number of each pixel, first dimension is RGB or
    % other, and second is pixel number
    num_valid_pixels = sum(img_mask{i}(:));
    hc_goal_rgb = zeros(size_3, num_valid_pixels);
    
    % Do discretization (histogram) into n_bins
    for j=1:size_3
        sub_img = img{i}(:, :, j);
        hc_goal_rgb(j,:) = discretize(sub_img(img_mask{i}), edges);
    end
    
    % Convert to single index, from 1 to bin_combinations
    hc_goal_idx_single = to_one_dim * (hc_goal_rgb - 1) + 1;
    
    assert(all(hc_goal_idx_single) >= 1, 'Invalid discretization');
    assert(all(hc_goal_idx_single) <= n_bins^size_3, 'Invalid discretization');
    
    % Do a histogram count using the combined bin indices and normalize by
    % the total number of pixels
    hc_goal = hc_goal + histcounts( hc_goal_idx_single, edges_all) ./ num_valid_pixels;
end

% Normalize by the number of goal images
hc_goal = hc_goal ./ num_goal;

end

