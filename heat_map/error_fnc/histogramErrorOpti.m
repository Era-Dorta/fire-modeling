function [ cerror ] = histogramErrorOpti( goal_im, imga )
%HISTOGRAM_ERROR_OPTI Computes an error measure between two images
%   CERROR = HISTOGRAM_ERROR_OPTI(IMGA, GOAL_IM) this is an optimized
%   version of HISTOGRAM_ERROR, assumes RGB images, ignores black pixels
%   and if the goal image changes, call clear 'histogramErrorOpti';

persistent N_GOAL NORM_FACTOR

% Create 256 bins, image can be 0..255
edges = linspace(0, 255, 256);

if isempty(N_GOAL)
    N_GOAL(1, :) = histcounts( goal_im(:, :, 1), edges);
    N_GOAL(2, :) = histcounts( goal_im(:, :, 2), edges);
    N_GOAL(3, :) = histcounts( goal_im(:, :, 3), edges);
    
    % Normalization factor is the inverse of the number of pixels
    NORM_FACTOR = 1 / numel(goal_im);
end

% Compute the histogram count for each color channel
Na(1, :) = histcounts( imga(:, :, 1), edges);
Na(2, :) = histcounts( imga(:, :, 2), edges);
Na(3, :) = histcounts( imga(:, :, 3), edges);

% The first bin is for black, ignore it
bin_range = 1:size(Na, 2);

% Compute the error as in Dobashi et. al. 2012
cerror = (sum(abs(Na(1, bin_range) - N_GOAL(1, bin_range))) + ...
    sum(abs(Na(2, bin_range) - N_GOAL(2, bin_range))) + ...
    sum(abs(Na(3, bin_range) - N_GOAL(3, bin_range)))) * NORM_FACTOR;

end
