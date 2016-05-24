function visualize_score_space( data_file, fig_save_path )
%VISUALIZE_SCORE_SPACE Create plots of GA population in 2D space
%   VISUALIZE_SCORE_SPACE( DATA_FILE, FIG_SAVE_PATH )

% Create folder for the data
out_folder = fileparts(fig_save_path);
mkdir(out_folder);

%% Load data and compute multidimensional scaling
L = load(data_file);

in_data = [L.AllPopulation];
scores = L.AllScores;

pairDists = pdist(in_data, 'euclidean');

Y = cmdscale(pairDists, 2); % Project pairDists to a 2 Dimensional space

%% Plot the data
% Create a new figure
if isBatchMode()
    fig_h = figure('Visible', 'off');
else
    fig_h = figure('Position', [1316 28 570 422]);
end

popSize = L.PopulationSize;
num_iterations = size(in_data, 1) / popSize;
min_idx = [0, 0];

offset = 0;

%% Plot once to get axis limits
scatter(Y(:, 1), Y(:,2));
x_axis_lim = xlim();
y_axis_lim = ylim();

%% Simple case with one iteration only
if num_iterations == 1
    i = 1;
    
    clf(fig_h);
    
    hold on;
    xlim(x_axis_lim);
    ylim(y_axis_lim);
    
    % Scatter has a legend color bug, do some hidden plots to get the
    % colors right in the legend
    hl1 = plot(1, 1, 'gx');
    hl1.Visible = 'off';
    
    scatter(Y(offset+1: popSize+offset, 1), Y(offset+1:popSize+offset,2), 'gx');
    
    [~, min_idx(1)] = min(scores(i,:));
    min_idx(1) = min_idx(1) + offset;
    
    % Start with a star
    hl2 = plot(Y(min_idx(1), 1), Y(min_idx(1),2), '*r');
    
    % Legend using only the handlers that we are interested in
    h_legend = legend([hl1, hl2], 'Initial Population',  ...
        'Optimization Path Start Point' , 'Location', 'northoutside', ...
        'Orientation','horizontal');
    h_legend.FontSize = 6;
    hold off;
    
    istr = sprintf('%03d', i - 1);
    saveas(fig_h, [fig_save_path istr], 'tiff');
    saveas(fig_h, [fig_save_path istr], 'svg');
    return;
end

%% Do a plot for each iteration

% Create a video as well
outputVideo = VideoWriter([fig_save_path '.avi']);
outputVideo.FrameRate = 2;
open(outputVideo);

for i=1:num_iterations-1
    clf(fig_h);
    
    hold on;
    
    % Set common limits so that visualization becomes easier
    xlim(x_axis_lim);
    ylim(y_axis_lim);
    
    % Scatter has a legend color bug, do some hidden plots to get the
    % colors right in the legend
    hl1 = plot(1, 1, 'gx');
    hl1.Visible = 'off';
    hl2 = plot(1, 1, 'bx');
    hl2.Visible = 'off';
    
    scatter(Y(offset+1: popSize+offset, 1), Y(offset+1:popSize+offset,2), 'gx');
    
    [~, min_idx(1)] = min(scores(i,:));
    min_idx(1) = min_idx(1) + offset;
    
    offset = offset + popSize;
    
    scatter(Y(offset+1: popSize+offset, 1), Y(offset+1:popSize+offset,2), 'bx');
    
    [~, min_idx(2)] = min(scores(i+1,:));
    min_idx(2) = min_idx(2) + offset;
    
    % Start with a star
    hl3 = plot(Y(min_idx(1), 1), Y(min_idx(1),2), '*r');
    
    % Line from start to second
    plot(Y(min_idx(1:2), 1), Y(min_idx(1:2),2), '--r');
    
    % End with a o
    hl4 = plot(Y(min_idx(2), 1), Y(min_idx(2), 2), '--or');
    
    % Legend using only the handlers that we are interested in
    h_legend = legend([hl1, hl2, hl3, hl4], 'Initial Population', 'Final Population', ...
        'Start Point', 'Optimization Path', 'Location', ...
        'northoutside', 'Orientation', 'horizontal');
    h_legend.FontSize = 6;
    hold off;
    
    istr = sprintf('%03d', i - 1);
    saveas(fig_h, [fig_save_path istr], 'tiff');
    saveas(fig_h, [fig_save_path istr], 'svg');
    
    writeVideo(outputVideo, getframe(fig_h));
end

close(outputVideo);

% Move svg files to a separate folder
mkdir(out_folder, 'svg');
movefile([fig_save_path '*.svg'], fullfile(out_folder, 'svg'));

end
