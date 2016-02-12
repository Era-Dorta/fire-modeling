function [ cerror ] = histogramErrorOptiN( goal_imgs, test_imgs, img_mask)
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
    
    for i=1:numel(goal_imgs)
        HC_GOAL{i}(1, :) = histcounts( goal_imgs{i}(:, :, 1), edges);
        HC_GOAL{i}(2, :) = histcounts( goal_imgs{i}(:, :, 2), edges);
        HC_GOAL{i}(3, :) = histcounts( goal_imgs{i}(:, :, 3), edges);
        
        % Normalize by the number of pixels not counting the black ones
        HC_GOAL{i}(1, :) = HC_GOAL{i}(1, :) / (size(goal_imgs{i}, 1) * ...
            size(goal_imgs{i}, 2) - HC_GOAL{i}(1, 1));
        HC_GOAL{i}(2, :) = HC_GOAL{i}(2, :) / (size(goal_imgs{i}, 1) * ...
            size(goal_imgs{i}, 2) - HC_GOAL{i}(2, 1));
        HC_GOAL{i}(3, :) = HC_GOAL{i}(3, :) / (size(goal_imgs{i}, 1) * ...
            size(goal_imgs{i}, 2) - HC_GOAL{i}(3, 1));
        
        % Set goal image as not having black pixels
        HC_GOAL{i}(:,1) = 0;
    end
    TESTIM_FACTOR = 1 / sum(img_mask(:) == 1);
end

% Compute the error as in Dobashi et. al. 2012
cerror = 0;
for i=1:numel(goal_imgs)
    
    % Compute the histogram count for each color channel
    subImga = test_imgs{i}(:, :, 1);
    hc_test(1, :) = histcounts(subImga(img_mask), edges) * TESTIM_FACTOR;
    
    subImga = test_imgs{i}(:, :, 2);
    hc_test(2, :) = histcounts(subImga(img_mask), edges) * TESTIM_FACTOR;
    
    subImga = test_imgs{i}(:, :, 3);
    hc_test(3, :) = histcounts(subImga(img_mask), edges) * TESTIM_FACTOR;
    
    cerror = cerror + (sum(abs(hc_test(1, :) - HC_GOAL{i}(1, :))) + ...
        sum(abs(hc_test(2, :) - HC_GOAL{i}(2, :))) + ...
        sum(abs(hc_test(3, :) - HC_GOAL{i}(3, :)))) / 3;
end

end
