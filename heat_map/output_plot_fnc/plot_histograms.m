function plot_histograms( n_bins, color_space, is_histo_independent, ...
    output_folder, goal_imgs, goal_mask,  opti_img, opti_mask)
%PLOT_HISTOGRAMS Plot and save histograms
%   PLOT_HISTOGRAMS( N_BINS, COLOR_SPACE, IS_HISTO_INDEPENDENT, ...
%   OUTPUT_FOLDER, GOAL_IMGS, GOAL_MASK,  OPTI_IMG, OPTI_MASK)

if isBatchMode()
    fig_h = figure('Visible', 'off');
else
    fig_h = figure('Position', [125 500 560 420]);
end

%% Save histograms for optmized images and goal images
output_folder = fullfile(output_folder, 'histogram_compare');
mkdir(output_folder);

plot_c = 'rgb';
edges = linspace(0, 255, n_bins+1);

plot_and_save(goal_imgs, goal_mask, 'GoalHisto');
plot_and_save(opti_img, opti_mask, 'OptiHisto');

%% Functions that do the actual work
%  Having them here avoids large argument calls
    function plot_and_save(imgs, masks, img_name)
        for i=1:numel(imgs)
            istr = num2str(i);
            
            % Compute histograms
            if is_histo_independent
                hc_img = getImgRGBHistogram( imgs{i}, masks{i}, ...
                    n_bins, edges);
            else
                hc_img = getImgCombinedHistogram( imgs{i}, ...
                    masks{i}, n_bins, edges);
            end
            % Normalise
            hc_img = hc_img ./ sum(masks{i}(:) == 1);
            
            % Save and plot each color dimension independently
            for j=1:size(hc_img,1)
                do_plot(hc_img(j,:), plot_c(j));
                save_img([img_name istr '-' color_space(j)]);
            end
        end
        
        function do_plot(hc, color)
            clf(fig_h);
            hold on;
            set(groot, 'CurrentFigure', fig_h);
            xlabel('Bin number');
            ylabel('Normalised bin count');
            xlim([1,n_bins]);
            bar(hc, color);
            hold off;
        end
        
        function save_img(file_name)
            %saveas(fig_h, fullfile(output_img_folder, file_name), 'tiff');
            saveas(fig_h, fullfile(output_folder, file_name), 'svg');
        end
        
    end

end
