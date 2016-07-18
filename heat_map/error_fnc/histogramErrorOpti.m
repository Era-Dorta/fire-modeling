function [ cerror ] = histogramErrorOpti( goal_imgs, test_imgs, goal_mask, ...
    img_mask, d_foo, n_bins, is_histo_independent, histo_w)
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

% Create n_bins bins
edges = linspace(0, 255, n_bins+1);

if isempty(HC_GOAL)
    HC_GOAL = cell(numel(goal_imgs), 1);
    TESTIM_FACTOR = zeros(1, numel(goal_imgs));
    
    for i=1:numel(goal_imgs)
        if is_histo_independent
            HC_GOAL{i} = getImgRGBHistogram( goal_imgs{i}, goal_mask{i}, ...
                n_bins, edges);
        else
            HC_GOAL{i} = getImgCombinedHistogram( goal_imgs{i}, ...
                goal_mask{i}, n_bins, edges);
        end
        HC_GOAL{i} = HC_GOAL{i} ./ sum(goal_mask{i}(:) == 1);
        
        TESTIM_FACTOR(i) = 1 / sum(img_mask{i}(:) == 1);
    end
end

% Compute the error as in Dobashi et. al. 2012
cerror = 0;
single_error = zeros(numel(histo_w), 1);
for i=1:numel(test_imgs)
    if is_histo_independent
        hc_test = getImgRGBHistogram( test_imgs{i}, img_mask{i}, ...
            n_bins, edges);
    else
        hc_test = getImgCombinedHistogram( test_imgs{i}, img_mask{i}, ...
            n_bins, edges);
    end
    
    % Normalize
    hc_test = hc_test * TESTIM_FACTOR(i);
    
    
    for j=1:size(HC_GOAL{i}, 1)
        single_error(j) = d_foo(hc_test(j, :), HC_GOAL{i}(j, :));
    end
    cerror = cerror + histo_w * single_error;
end

% Divide by the number of images so that the error function is still in the
% range of 0..1
% N.B. Divide by test_imgs and not goal_imgs, so that if two goal images
% are given but only one test_imgs, it still outputs the right result
cerror = cerror ./ numel(test_imgs);

assert_valid_range_in_0_1(cerror);

end
