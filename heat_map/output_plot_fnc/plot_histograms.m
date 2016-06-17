function plot_histograms( opts, num_goal,  output_folder, goal_imgs, ...
    goal_mask, img_mask)
%PLOT_HISTOGRAMS Plot and save histograms
%   PLOT_HISTOGRAMS( OPTS, NUM_GOAL,  OUTPUT_FOLDER, GOAL_IMGS, ...
%    GOAL_MASK, IMG_MASK)

if isBatchMode()
    fig_h = figure('Visible', 'off');
else
    fig_h = figure('Position', [125 500 560 420]);
end

%% Read optimized images
c_img = cell(num_goal, 1);
for k=1:num_goal
    c_img{k} = imread(fullfile(output_folder, ...
        [ 'optimized-Cam' num2str(k) '.tif']));
    c_img{k} = c_img{k}(:,:,1:3); % Transparency is not used, so ignore it
end

c_img = colorspace_transform_imgs(c_img, 'RGB', opts.color_space);

%% Save histograms for optmized images and goal images
output_folder = fullfile(output_folder, 'histogram_compare');
mkdir(output_folder);

edges = linspace(0, 255, opts.n_bins+1);
plot_and_save(goal_imgs, goal_mask, 'GoalHisto');
plot_and_save(c_img, img_mask, 'OptiHisto');

%% Functions that do the actual work
%  Having them here avoids large argument calls
    function plot_and_save(imgs, masks, img_name)
        for i=1:numel(imgs)
            istr = num2str(i);
            
            % Compute histograms
            if opts.is_histo_independent
                hc_img = getImgRGBHistogram( imgs{i}, masks{i}, ...
                    opts.n_bins, edges);
            else
                hc_img = getImgCombinedHistogram( imgs{i}, ...
                    masks{i}, opts.n_bins, edges);
            end
            % Normalise
            hc_img = hc_img ./ sum(masks{i}(:) == 1);
            
            % Save and plot each color dimension independently
            for j=1:size(hc_img,1)
                do_plot(hc_img(j,:));
                save_img(img_name);
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

end

