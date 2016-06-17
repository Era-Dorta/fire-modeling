function plot_histograms( opts, num_goal,  output_folder, goal_imgs, ...
    goal_mask, img_mask)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if isBatchMode()
    fig_h = figure('Visible', 'off');
else
    fig_h = figure('Position', [125 500 560 420]);
end

%% Read optimized images
c_img = cell(num_goal, 1);
for i=1:num_goal
    c_img{i} = imread(fullfile(output_folder, ...
        [ 'optimized-Cam' num2str(i) '.tif']));
    c_img{i} = c_img{i}(:,:,1:3); % Transparency is not used, so ignore it
end

c_img = colorspace_transform_imgs(c_img, 'RGB', opts.color_space);

%% Save histograms for optmized images and goal images
output_folder = fullfile(output_folder, 'histogram_compare');
mkdir(output_folder);

edges = linspace(0, 255, opts.n_bins+1);
for i=1:numel(goal_imgs)
    istr = num2str(i);
    
    % Compute histograms
    if opts.is_histo_independent
        hc_goal = getImgRGBHistogram( goal_imgs{i}, goal_mask{i}, ...
            opts.n_bins, edges);
        hc_test = getImgRGBHistogram( c_img{i}, img_mask{i}, ...
            opts.n_bins, edges);
    else
        hc_goal = getImgCombinedHistogram( goal_imgs{i}, ...
            goal_mask{i}, opts.n_bins, edges);
        hc_test = getImgCombinedHistogram( c_img{i}, img_mask{i}, ...
            opts.n_bins, edges);
    end
    % Normalise
    hc_goal = hc_goal ./ sum(goal_mask{i}(:) == 1);
    hc_test = hc_test ./ sum(img_mask{i}(:) == 1);
    
    % Save and plot each color dimension independently
    for j=1:size(hc_goal,1)
        do_plot(hc_goal(j,:));
        save_img('GoalHisto');
        
        do_plot(hc_test(j,:));
        save_img('OptiHisto');
    end
end

    function do_plot(hc)
        clf(fig_h);
        hold on;
        set(groot, 'CurrentFigure', fig_h);
        xlabel('Bin number');
        ylabel('Normalised bin count');
        xlim([1,opts.n_bins]);
        bar(hc);
        hold off;
    end

    function save_img(img_name)
        file_name = [img_name istr '-' opts.color_space(j)];
        %saveas(fig_h, fullfile(output_img_folder, file_name), 'tiff');
        saveas(fig_h, fullfile(output_folder, file_name), 'svg');
    end

end

