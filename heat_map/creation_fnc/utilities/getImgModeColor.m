function [ out_rgb ] = getImgModeColor( img, img_mask, n_bins)
%GETIMGMODECOLOR Get color estimate from image
%   [ OUT_RGB ] = GETIMGMODECOLOR( IMG, IMG_MASK, N_BINS) Color is
%   computed using the mode. IMG is a cell of color images, IMG_MASK a cell
%   of logical mask images, and N_BINS is the number of bins for the
%   histogram used to compute de mode. The image/s mode color is given in
%   OUT_RGB.
%
%   See also getImgMeanColor, getImgStdColor

%% Compute histogram of the goal image

% Create n_bins bins for the histogram
edges = linspace(0, 255, n_bins+1);

% Multi goal optimization, compute the mean histogram of all the goal
% images
hc_goal = zeros(3, n_bins);
num_goal = numel(img);
for i=1:num_goal
    if(size(img_mask{i}, 3) == 3)
        img_mask{i}= img_mask{i}(:,:,1);
    end
    
    sub_img = img{i}(:, :, 1);
    hc_goal(1, :) = hc_goal(1, :) + histcounts( sub_img(img_mask{i}), edges);
    
    sub_img = img{i}(:, :, 2);
    hc_goal(2, :) = hc_goal(2, :) + histcounts( sub_img(img_mask{i}), edges);
    
    sub_img = img{i}(:, :, 3);
    hc_goal(3, :) = hc_goal(3, :) + histcounts( sub_img(img_mask{i}), edges);
end
hc_goal = hc_goal ./ num_goal;

% Get the most common RGB value
[~, out_rgb] = max(hc_goal, [], 2);
out_rgb = out_rgb';

end

