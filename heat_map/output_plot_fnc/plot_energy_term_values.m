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
for k=1:numel(goal_imgs)
    size_temp = size(opti_img{k});
    goal_imgs{k} = imresize(goal_imgs{k}, size_temp(1:2));
    size_temp = size(opti_mask{k});
    goal_mask{k} = imresize(goal_mask{k}, size_temp(1:2));
end

out_ylim = plot_img_side_dist( opts.color_space, opts.is_histo_independent, ...
    output_folder, goal_imgs, goal_mask, 'GoalHisto');

plot_img_side_dist( opts.color_space, opts.is_histo_independent, ...
    output_folder, opti_img, opti_mask, 'OptiHisto', out_ylim);

plot_img_side_dist( opts.color_space, opts.is_histo_independent, ...
    output_folder, first_img, opti_mask, 'FirstIteHisto', out_ylim);

plot_img_side_dist( opts.color_space, opts.is_histo_independent, ...
    output_folder, blur_opti_img, opti_mask, 'BlurOptiHisto', out_ylim);

end

