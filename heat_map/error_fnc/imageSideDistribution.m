function [ cerror ] = imageSideDistribution( goal_imgs, test_imgs, goal_mask, ...
    img_mask, d_foo, is_histo_independent)
%IMAGESIDEDISTRIBUTION Compues an error measure between several images
%   [ CERROR ] = IMAGESIDEDISTRIBUTION( GOAL_IMGS, TEST_IMGS, GOAL_MASK, ...
%   IMG_MASK, D_FOO, IS_HISTO_INDEPENDENT)
%
%   See also HISTOGRAMERROR

persistent HC_GOAL

if isempty(HC_GOAL)
    HC_GOAL = cell(numel(goal_imgs), 2);
    
    for i=1:numel(goal_imgs)
        size_temp = size(test_imgs{i});
        goal_imgs{i} = imresize(goal_imgs{i}, size_temp(1:2));
        size_temp = size(img_mask{i});
        goal_mask{i} = imresize(goal_mask{i}, size_temp(1:2));
        
        if is_histo_independent
            [HC_GOAL{i, 1}, HC_GOAL{i, 2}]  = getImghvRGBHistogram( ...
                goal_imgs{i}, goal_mask{i});
        else
            error('Not supported');
        end
    end
end

cerror = 0;
for i=1:numel(test_imgs)
    hc_test = {[], []};
    if is_histo_independent
        [hc_test{1}, hc_test{2}]  = getImghvRGBHistogram( ...
            test_imgs{i}, img_mask{i});
    else
        error('Not supported');
    end
    
    single_error = 0;
    for j=1:size(HC_GOAL{i}, 1)
        single_error = single_error + d_foo(hc_test{1}(j, :), ...
            HC_GOAL{i, 1}(j, :)) + d_foo(hc_test{2}(j, :), ...
            HC_GOAL{i, 2}(j, :));
    end
    cerror = cerror + single_error / size(HC_GOAL{i}, 1);
end

% Divide by the number of images so that the error function is still in the
% range of 0..1
% N.B. Divide by test_imgs and not goal_imgs, so that if two goal images
% are given but only one test_imgs, it still outputs the right result
cerror = cerror ./ (2 * numel(test_imgs));

assert_valid_range_in_0_1(cerror);

end
