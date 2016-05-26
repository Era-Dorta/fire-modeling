function histoE = histogramErrorApprox( v, goal_img, goal_mask, d_foo, ...
    fuel_type, n_bins, is_histo_independent, color_space)
%HISTOGRAMERRORAPPROX computes an error measure between v and goal image
%   HISTOE = HISTOGRAMERRORAPPROX( V, GOAL_IMG, GOAL_MASK ) V is a value
%   matrix NxM, with N heat maps with M values per heat map. GOAL_IMG is
%   and PxQ RGB of image and GOAL_MASK is a PxQ logical matrix used as a
%   mask for GOAL_IMG, HISTOE is the error value

persistent CTtable GoalHisto NumGoal

% Create n_bins bins
edges = linspace(0, 255, n_bins+1);

if(isempty(CTtable))
    % Get Color-Temperature table
    code_dir = fileparts(fileparts(mfilename('fullpath')));
    CTtable = load([code_dir '/data/CT-' get_fuel_name(fuel_type) '.mat'], ...
        '-ascii');
    
    % Conver the RGB values in the Color-Temperature table to a new color
    % space
    colorsCT = reshape(CTtable(:,2:4), size(CTtable, 1), 1, 3);
    colorsCT = colorspace_transform_imgs({colorsCT}, 'RGB', color_space);
    CTtable(:,2:4) = reshape(colorsCT{1}, size(CTtable, 1), 3);
    
    % Precompute histograms for the goal image/s
    NumGoal = numel(goal_img);
    GoalHisto = cell(NumGoal, 1);
    
    for i=1:NumGoal
        if is_histo_independent
            GoalHisto{i} = getImgRGBHistogram( goal_img{i}, goal_mask{i}, ...
                n_bins, edges, true);
        else
            GoalHisto{i} = getImgCombinedHistogram( goal_img{i}, ...
                goal_mask{i}, n_bins, edges, true);
        end
    end
end

% interp_method = 'nearest'; % C0
interp_method = 'linear'; % C0
% interp_method = 'cubic'; % C1
% interp_method = 'spline'; % C2

num_vol = size(v, 1);
histoE = zeros(1, num_vol);

num_temp = size(v, 2);
num_temp_inv = 1.0 / num_temp;

img_mask = true(num_temp, 1);

for i=1:num_vol
    % Get the estimated color for each voxel using the table, as the
    % temperatures in the table are discrete samples, use an interpolation
    % method to get the colors for the current temperatures, assume that
    % anything outside the table is black [0, 0, 0]
    colors_est = interp1(CTtable(:, 1), CTtable(:, 2:4), v(i,:), ...
        interp_method, 0);
    
    % Compute the histograms, treating the estimates as an image
    colors_est = reshape(colors_est, num_temp, 1, 3);
    if is_histo_independent
        histo_est = getImgRGBHistogram( colors_est, img_mask, ...
            n_bins, edges);
    else
        histo_est = getImgCombinedHistogram( colors_est, img_mask, ...
            n_bins, edges);
    end
    
    % Normalize by the number of voxels, which should be equivalent to
    % normalize by the number of pixels, in the end just getting a normalized
    % histogram
    histo_est = histo_est * num_temp_inv;
    
    for j=1:NumGoal
        single_error = 0;
        for k=1:size(GoalHisto{j}, 1)
            single_error = single_error + d_foo(histo_est(k, :), ...
                GoalHisto{j}(k, :));
        end
        histoE(i) = histoE(i) + single_error / size(GoalHisto{j}, 1);
    end
end

histoE = histoE ./ NumGoal;

assert_valid_range_in_0_1(histoE);

end
