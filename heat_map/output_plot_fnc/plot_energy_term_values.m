function plot_energy_term_values( opts, num_goal,  output_folder, goal_imgs, ...
    goal_mask, opti_mask )
%PLOT_ENERGY_TERM_VALUES Plot and save energy terms
%   PLOT_ENERGY_TERM_VALUES( OPTS, NUM_GOAL,  OUTPUT_FOLDER, GOAL_IMGS, ...
%   GOAL_MASK, OPTI_MASK )
%% Read optimized images
opti_img = cell(num_goal, 1);
first_img = cell(num_goal, 1);
blur_opti_img = cell(num_goal, 1);
for k=1:num_goal
    opti_img{k} = imread(fullfile(output_folder, ...
        [ 'optimized-Cam' num2str(k) '.tif']));
    first_img{k} = imread(fullfile(output_folder, ...
        [ 'best-iter0-Cam' num2str(k) '.tif']));
    blur_opti_img{k} = imread(fullfile(output_folder, ...
        [ 'optimized-blurred-Cam' num2str(k) '.tif']));
    
    opti_img{k} = opti_img{k}(:,:,1:3); % Transparency is not used, so ignore it
    first_img{k} = first_img{k}(:,:,1:3);
    blur_opti_img{k} = blur_opti_img{k}(:,:,1:3);
end

opti_img = colorspace_transform_imgs(opti_img, 'RGB', opts.color_space);

%% Plot the simple image histograms
out_ylim = plot_histograms(opts.n_bins, opts.color_space, opts.is_histo_independent, ...
    output_folder, goal_imgs, goal_mask, 'GoalHisto');

plot_histograms(opts.n_bins, opts.color_space, opts.is_histo_independent, ...
    output_folder, opti_img, opti_mask, 'OptiHisto', out_ylim);

plot_histograms(opts.n_bins, opts.color_space, opts.is_histo_independent, ...
    output_folder, first_img, opti_mask, 'FirstIteHisto', out_ylim);

plot_histograms(opts.n_bins, opts.color_space, opts.is_histo_independent, ...
    output_folder, blur_opti_img, opti_mask, 'BlurOptiHisto', out_ylim);

%% Plot the side distribution histograms

% Make the goal images have the same size as the optimised
goal_imgs1 = goal_imgs;
goal_mask1 = goal_mask;
for k=1:numel(goal_imgs)
    size_temp = size(opti_img{k});
    goal_imgs1{k} = imresize(goal_imgs{k}, size_temp(1:2));
    size_temp = size(opti_mask{k});
    goal_mask1{k} = imresize(goal_mask{k}, size_temp(1:2));
end

out_ylim = plot_img_side_dist( opts.color_space, opts.is_histo_independent, ...
    output_folder, goal_imgs1, goal_mask1, 'GoalHisto');

plot_img_side_dist( opts.color_space, opts.is_histo_independent, ...
    output_folder, opti_img, opti_mask, 'OptiHisto', out_ylim);

plot_img_side_dist( opts.color_space, opts.is_histo_independent, ...
    output_folder, first_img, opti_mask, 'FirstIteHisto', out_ylim);

plot_img_side_dist( opts.color_space, opts.is_histo_independent, ...
    output_folder, blur_opti_img, opti_mask, 'BlurOptiHisto', out_ylim);

%% Plot the side invariant distribution histograms

% Make the goal images have the same size as the optimised
goal_imgs2 = goal_imgs;
goal_mask2 = goal_mask;
img_x_lim = zeros(numel(opti_img), 2);
img_y_lim = zeros(numel(opti_img), 2);
goal_x_lim = zeros(numel(goal_imgs), 2);
goal_y_lim = zeros(numel(goal_imgs), 2);

for k=1:numel(goal_imgs)
    [img_x_lim(k,:), img_y_lim(k,:)] = bounding_box_limits(opti_mask{k});
    [goal_x_lim(k,:), goal_y_lim(k,:)] = bounding_box_limits(goal_mask{k});
    
    % Crop goal image and mask using the bounding box
    goal_imgs2{k} = cropimg(goal_imgs{k}, goal_x_lim, goal_y_lim);
    goal_mask2{k} = cropimg(goal_mask{k}, goal_x_lim, goal_y_lim);
    
    % Resize the goal so that it has the same number of pixels as the
    % synthetic image
    new_size = [img_x_lim(k,2) - img_x_lim(k,1) + 1, ...
        img_y_lim(k,2) - img_y_lim(k,1) + 1];
    goal_imgs2{k} = imresize(goal_imgs2{k}, new_size);
    goal_mask2{k} = imresize(goal_mask2{k}, new_size);
    
    goal_x_lim(k,:) = [1, new_size(1)];
    goal_y_lim(k,:) = [1, new_size(2)];
end

out_ylim = plot_img_side_dist_inv( opts.color_space, opts.is_histo_independent, ...
    output_folder, goal_imgs2, goal_mask2, 'GoalHisto', goal_x_lim, goal_y_lim);

plot_img_side_dist_inv( opts.color_space, opts.is_histo_independent, ...
    output_folder, opti_img, opti_mask, 'OptiHisto', img_x_lim, ...
    img_y_lim, out_ylim);

plot_img_side_dist_inv( opts.color_space, opts.is_histo_independent, ...
    output_folder, first_img, opti_mask, 'FirstIteHisto', img_x_lim, ...
    img_y_lim, out_ylim);

plot_img_side_dist_inv( opts.color_space, opts.is_histo_independent, ...
    output_folder, blur_opti_img, opti_mask, 'BlurOptiHisto', img_x_lim, ...
    img_y_lim, out_ylim);

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

