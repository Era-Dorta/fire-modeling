function [ cerror ] = histogramErrorOpti( goal_imgs, test_imgs, goal_mask, ...
    img_mask, d_foo)
%HISTOGRAMERROROPTI Compues an error measure between several images
%   CERROR = HISTOGRAMERROROPTI(GOAL_IMGS, TEST_IMGS, GOAL_MASK, IMG_MASK)
%   this is an optimized version of HISTOGRAMERROR, assumes RGB images,
%   for the catching mechanism to work consistently, if the goal image
%   changes, call clear 'HISTOGRAMERROROPTI';
%   GOAL_IMGS and TEST_IMGS are same sized cells with the images to
%   compare, GOAL_MASK and IMG_MASK are same sized cells with logical
%   two dimensional matrices to mask GOAL_IMGS and TEST_IMGS respectively.
%   If TEST_IMGS and IMG_MASK contain less images than GOAL_IMGS, the
%   comparison will be performed with the first GOAL_IMGS.
%
%   See also HISTOGRAMERROR

persistent HC_GOAL TESTIM_FACTOR

% Create 255 bins, images are uint in the range of 0..255
edges = linspace(0, 255, 256);

if isempty(HC_GOAL)
    HC_GOAL = cell(numel(goal_imgs), 1);
    TESTIM_FACTOR = zeros(1, numel(goal_imgs));
    
    for i=1:numel(goal_imgs)
        sub_img = goal_imgs{i}(:, :, 1);
        HC_GOAL{i}(1, :) = histcounts( sub_img(goal_mask{i}), edges);
        sub_img = goal_imgs{i}(:, :, 2);
        HC_GOAL{i}(2, :) = histcounts( sub_img(goal_mask{i}), edges);
        sub_img = goal_imgs{i}(:, :, 3);
        HC_GOAL{i}(3, :) = histcounts( sub_img(goal_mask{i}), edges);
        
        % Normalize by the number of pixels
        HC_GOAL{i} = HC_GOAL{i} ./ sum(goal_mask{i}(:) == 1);
        
        TESTIM_FACTOR(i) = 1 / sum(img_mask{i}(:) == 1);
    end
end

% Compute the error as in Dobashi et. al. 2012
cerror = 0;
for i=1:numel(test_imgs)
    
    % Compute the histogram count for each color channel
    subImga = test_imgs{i}(:, :, 1);
    hc_test(1, :) = histcounts(subImga(img_mask{i}), edges) * TESTIM_FACTOR(i);
    
    subImga = test_imgs{i}(:, :, 2);
    hc_test(2, :) = histcounts(subImga(img_mask{i}), edges) * TESTIM_FACTOR(i);
    
    subImga = test_imgs{i}(:, :, 3);
    hc_test(3, :) = histcounts(subImga(img_mask{i}), edges) * TESTIM_FACTOR(i);
    
    cerror = cerror + (d_foo(hc_test(1, :), HC_GOAL{i}(1, :)) + ...
        d_foo(hc_test(2, :), HC_GOAL{i}(2, :)) + ...
        d_foo(hc_test(3, :), HC_GOAL{i}(3, :))) / 3;
end

% Divide by the number of images so that the error function is still in the
% range of 0..1
% N.B. Divide by test_imgs and not goal_imgs, so that if two goal images
% are given but only one test_imgs, it still outputs the right result
cerror = cerror ./ numel(test_imgs);

assert_valid_range_in_0_1(cerror);

end
