function plot_energy_term_values( opts, num_goal,  output_folder, goal_imgs, ...
    goal_mask, opti_mask )
%PLOT_ENERGY_TERM_VALUES Plot and save energy terms
%   PLOT_ENERGY_TERM_VALUES( OPTS, NUM_GOAL,  OUTPUT_FOLDER, GOAL_IMGS, ...
%   GOAL_MASK, OPTI_MASK )
%% Read optimized images
opti_img = cell(num_goal, 1);
for k=1:num_goal
    opti_img{k} = imread(fullfile(output_folder, ...
        [ 'optimized-Cam' num2str(k) '.tif']));
    opti_img{k} = opti_img{k}(:,:,1:3); % Transparency is not used, so ignore it
end

opti_img = colorspace_transform_imgs(opti_img, 'RGB', opts.color_space);

%% Plot the different energy terms for the goal and optimize images
out_ylim = plot_histograms(opts.n_bins, opts.color_space, opts.is_histo_independent, ...
    output_folder, goal_imgs, goal_mask, 'GoalHisto');

plot_histograms(opts.n_bins, opts.color_space, opts.is_histo_independent, ...
    output_folder, opti_img, opti_mask, 'OptiHisto', out_ylim);

plot_img_side_dist( opts.color_space, opts.is_histo_independent, ...
    output_folder, goal_imgs, goal_mask,  opti_img, opti_mask)

end

