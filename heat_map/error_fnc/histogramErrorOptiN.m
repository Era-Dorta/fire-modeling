function [ cerror ] = histogramErrorOptiN( goal_imgs, test_imgs )
%HISTOGRAMERROROPTIN Computes an error measure between several images
%   CERROR = HISTOGRAMERROROPTIN(GOAL_IMGS, TEST_IMGS) this is an optimized
%   version of HISTOGRAM_ERROR, assumes RGB images, ignores black pixels
%   and if the goal image changes, call clear 'histogramErrorOptiN';
%   GOAL_IMGS and TEST_IMGS are same sized cells with the images to compare

persistent HC_GOAL NORM_FACTOR

% Create 256 bins, image can be 0..255
edges = linspace(0, 255, 256);

if isempty(HC_GOAL)
    HC_GOAL = cell(numel(goal_imgs), 1);
    NORM_FACTOR = zeros(numel(goal_imgs), 1);
    
    for i=1:numel(goal_imgs)
        HC_GOAL{i}(1, :) = histcounts( goal_imgs{i}(:, :, 1), edges);
        HC_GOAL{i}(2, :) = histcounts( goal_imgs{i}(:, :, 2), edges);
        HC_GOAL{i}(3, :) = histcounts( goal_imgs{i}(:, :, 3), edges);
        
        % Normalization factor is the inverse of the number of pixels
        NORM_FACTOR(i) = 1 / (numel(goal_imgs{i}) * numel(goal_imgs));
    end
end

% The first bin is for black, ignore it
bin_range = 2:size(HC_GOAL{1}, 2);

% Compute the error as in Dobashi et. al. 2012
cerror = 0;
for i=1:numel(NORM_FACTOR)
    
    % Compute the histogram count for each color channel
    hc_test(1, :) = histcounts( test_imgs{i}(:, :, 1), edges);
    hc_test(2, :) = histcounts( test_imgs{i}(:, :, 2), edges);
    hc_test(3, :) = histcounts( test_imgs{i}(:, :, 3), edges);
    
    cerror = cerror + (sum(abs(hc_test(1, bin_range) - HC_GOAL{i}(1, bin_range))) + ...
        sum(abs(hc_test(2, bin_range) - HC_GOAL{i}(2, bin_range))) + ...
        sum(abs(hc_test(3, bin_range) - HC_GOAL{i}(3, bin_range)))) * NORM_FACTOR(i);
end

end
