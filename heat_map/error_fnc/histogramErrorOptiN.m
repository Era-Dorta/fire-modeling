function [ cerror ] = histogramErrorOptiN( goal_imgs, test_imgs, goal_mask, ...
    img_mask)
%HISTOGRAMERROROPTIN Computes an error measure between several images
%   CERROR = HISTOGRAMERROROPTIN(GOAL_IMGS, TEST_IMGS) this is an optimized
%   version of HISTOGRAM_ERROR, assumes RGB images, ignores black pixels
%   and if the goal image changes, call clear 'histogramErrorOptiN';
%   GOAL_IMGS and TEST_IMGS are same sized cells with the images to compare

persistent HC_GOAL TESTIM_FACTOR

% Create 256 bins, image can be 0..255
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
for i=1:numel(goal_imgs)
    
    % Compute the histogram count for each color channel
    subImga = test_imgs{i}(:, :, 1);
    hc_test(1, :) = histcounts(subImga(img_mask{i}), edges) * TESTIM_FACTOR(i);
    
    subImga = test_imgs{i}(:, :, 2);
    hc_test(2, :) = histcounts(subImga(img_mask{i}), edges) * TESTIM_FACTOR(i);
    
    subImga = test_imgs{i}(:, :, 3);
    hc_test(3, :) = histcounts(subImga(img_mask{i}), edges) * TESTIM_FACTOR(i);
    
    cerror = cerror + (sum(abs(hc_test(1, :) - HC_GOAL{i}(1, :))) + ...
        sum(abs(hc_test(2, :) - HC_GOAL{i}(2, :))) + ...
        sum(abs(hc_test(3, :) - HC_GOAL{i}(3, :)))) / 6;
end

end
