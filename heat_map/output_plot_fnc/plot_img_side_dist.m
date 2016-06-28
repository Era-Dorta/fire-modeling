function plot_img_side_dist( color_space, is_histo_independent, ...
    output_folder, goal_imgs, goal_mask,  opti_img, opti_mask)
%PLOT_IMG_SIDE_DIST Plot and save side distribution
%   PLOT_IMG_SIDE_DIST( COLOR_SPACE, IS_HISTO_INDEPENDENT, ...
%   OUTPUT_FOLDER, GOAL_IMGS, GOAL_MASK,  OPTI_IMG, OPTI_MASK)

if isBatchMode()
    fig_h = figure('Visible', 'off');
else
    fig_h = figure('Position', [125 500 560 420]);
end

%% Make the images have the same size
for k=1:numel(goal_imgs)
    size_temp = size(opti_img{k});
    goal_imgs{k} = imresize(goal_imgs{k}, size_temp(1:2));
    size_temp = size(opti_mask{k});
    goal_mask{k} = imresize(goal_mask{k}, size_temp(1:2));
end

%% Save histograms for optmized images and goal images
output_folder = fullfile(output_folder, 'img_side_dist_compare');
mkdir(output_folder);

plot_c = 'rgb';

g_ylmin = plot_and_save(goal_imgs, goal_mask, 'GoalHisto');
plot_and_save(opti_img, opti_mask, 'OptiHisto', g_ylmin);

%% Functions that do the actual work
%  Having them here avoids large argument calls
    function out_ylim = plot_and_save(imgs, masks, img_name, in_ylim)
        out_ylim = cell(numel(imgs), 2);
        
        for i=1:numel(imgs)
            istr = num2str(i);
            
            % Compute histograms
            if is_histo_independent
                [hc_img_h, hc_img_v] = getImghvRGBHistogram(imgs{i}, masks{i});
            else
                error('Not supported');
            end
            
            % Save and plot each dimension independently
            for j=1:size(hc_img_h,1)
                do_plot(hc_img_h(j,:), 'Image row', plot_c(j));
                
                % Manually set axis
                if nargin == 4
                    hold on; ylim(in_ylim{i, 1}(j,:)); hold off;
                end
                out_ylim{i, 1}(j,:) = ylim();
                
                % For the horizontal is easier to visualize if the bars
                % are horizontal as well
                hold on; camroll(90); hold off;
                save_img([img_name istr '-horizontal-' color_space(j)]);
                
                do_plot(hc_img_v(j,:), 'Image column', plot_c(j));
                
                % Manually set axis
                if nargin == 4
                    hold on; ylim(in_ylim{i, 2}(j,:)); hold off;
                end
                out_ylim{i, 2}(j,:) = ylim();
                
                save_img([img_name istr '-vertical-' color_space(j)]);
            end
        end
        
        function do_plot(hc, x_label_name, color)
            clf(fig_h);
            hold on;
            set(groot, 'CurrentFigure', fig_h);
            xlabel(x_label_name);
            ylabel('Mean pixel value');
            xlim([1, numel(hc)]);
            bar(hc, color, 'EdgeColor', 'none');
            hold off;
        end
        
        function save_img(file_name)
            %saveas(fig_h, fullfile(output_img_folder, file_name), 'tiff');
            saveas(fig_h, fullfile(output_folder, file_name), 'svg');
        end
        
    end

end

