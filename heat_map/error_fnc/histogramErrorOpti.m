function [ cerror ] = histogramErrorOpti( goal_im, imga, img_mask )
%HISTOGRAMERROROPTI Computes an error measure between two images
%   CERROR = HISTOGRAMERROROPTI(IMGA, GOAL_IM) this is an optimized
%   version of HISTOGRAM_ERROR, assumes RGB images, ignores black pixels
%   and if the goal image changes, call clear 'histogramErrorOpti';

persistent HC_GOAL IMGA_FACTOR

% Create 256 bins, image can be 0..255
edges = linspace(0, 255, 256);

if isempty(HC_GOAL)
    HC_GOAL(1, :) = histcounts( goal_im(:, :, 1), edges);
    HC_GOAL(2, :) = histcounts( goal_im(:, :, 2), edges);
    HC_GOAL(3, :) = histcounts( goal_im(:, :, 3), edges);
    
    % Normalize by the number of pixels not counting the black ones
    HC_GOAL(1, :) = HC_GOAL(1, :) / (size(goal_im, 1) * size(goal_im, 2) - HC_GOAL(1, 1));
    HC_GOAL(2, :) = HC_GOAL(2, :) / (size(goal_im, 1) * size(goal_im, 2) - HC_GOAL(2, 1));
    HC_GOAL(3, :) = HC_GOAL(3, :) / (size(goal_im, 1) * size(goal_im, 2) - HC_GOAL(3, 1));
    
    % Set goal image as not having black pixels
    HC_GOAL(:,1) = 0;
    
    IMGA_FACTOR = 1 / sum(img_mask(:) == 1);
end

% Compute the histogram count for each color channel
subImga = imga(:, :, 1);
Na(1, :) = histcounts( subImga(img_mask), edges) * IMGA_FACTOR;

subImga = imga(:, :, 2);
Na(2, :) = histcounts( subImga(img_mask), edges) * IMGA_FACTOR;

subImga = imga(:, :, 3);
Na(3, :) = histcounts( subImga(img_mask), edges) * IMGA_FACTOR;

% Compute the error as in Dobashi et. al. 2012
cerror = (sum(abs(Na(1, :) - HC_GOAL(1, :))) + sum(abs(Na(2, :) - ...
    HC_GOAL(2, :))) + sum(abs(Na(3, :) - HC_GOAL(3, :)))) / 3;

end
