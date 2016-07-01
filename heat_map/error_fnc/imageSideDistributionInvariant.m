function [ cerror ] = imageSideDistributionInvariant( goal_imgs, test_imgs, ...
    goal_mask, img_mask, d_foo, is_histo_independent)
%IMAGESIDEDISTRIBUTIONINVARIANT Compues an error measure between several images
%   [ CERROR ] = IMAGESIDEDISTRIBUTIONINVARIANT( GOAL_IMGS, TEST_IMGS, ...
%   GOAL_MASK, IMG_MASK, D_FOO, IS_HISTO_INDEPENDENT)
%
%   See also HISTOGRAMERROR

persistent HC_GOAL IMG_X_LIM IMG_Y_LIM

if isempty(HC_GOAL)
    HC_GOAL = cell(numel(goal_imgs), 2);
    IMG_X_LIM = zeros(numel(test_imgs), 2);
    IMG_Y_LIM = zeros(numel(test_imgs), 2);
    
    for i=1:numel(goal_imgs)
        % Get mask bounding box around the fire
        [IMG_X_LIM(i,:), IMG_Y_LIM(i,:)] = bounding_box_limits(img_mask{i});
        [goal_x_lim, goal_y_lim] = bounding_box_limits(goal_mask{i});
        
        % Crop goal image and mask using the bounding box
        goal_imgs{i} = cropimg(goal_imgs{i}, goal_x_lim, goal_y_lim);
        goal_mask{i} = cropimg(goal_mask{i}, goal_x_lim, goal_y_lim);
        
        % Resize the goal so that it has the same number of pixels as the
        % synthetic image
        new_size = [IMG_X_LIM(i,2) - IMG_X_LIM(i,1) + 1, ...
            IMG_Y_LIM(i,2) - IMG_Y_LIM(i,1) + 1];
        goal_imgs{i} = imresize(goal_imgs{i}, new_size);
        goal_mask{i} = imresize(goal_mask{i}, new_size);
        
        goal_x_lim = [1, new_size(1)];
        goal_y_lim = [1, new_size(2)];
        
        if is_histo_independent
            [HC_GOAL{i, 1}, HC_GOAL{i, 2}]  = getCropImghvRGBHistogram( ...
                goal_imgs{i}, goal_mask{i}, goal_x_lim, goal_y_lim);
        else
            error('Not supported');
        end
    end
end

cerror = 0;
for i=1:numel(test_imgs)
    hc_test = {[], []};
    if is_histo_independent
        [hc_test{1}, hc_test{2}]  = getCropImghvRGBHistogram( ...
            test_imgs{i}, img_mask{i}, IMG_X_LIM(i,:), IMG_Y_LIM(i,:));
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

%% Auxiliary functions
    function [xlims, ylims] = bounding_box_limits(img)
        xlims = [0,0];
        ylims = [0,0];
        
        [valid_all_x, valid_all_y] = find(img == 1);
        
        xlims(1) = min(valid_all_x);
        xlims(2) = max(valid_all_x);
        
        ylims(1) = min(valid_all_y);
        ylims(2) = max(valid_all_y);
    end

    function out_img = cropimg(img, xlims, ylims)
        out_img = img(xlims(1):xlims(2),ylims(1):ylims(2), :);
    end

end
