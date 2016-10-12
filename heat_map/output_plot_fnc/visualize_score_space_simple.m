function visualize_score_space_simple( data_file, fig_save_path )
%VISUALIZE_SCORE_SPACE Create plots of GA population in 2D space
%   VISUALIZE_SCORE_SPACE( DATA_FILE, FIG_SAVE_PATH )

% Create folder for the data
out_folder = fileparts(fig_save_path);
mkdir(out_folder);

%% Load data and compute multidimensional scaling
L = load(data_file);

in_data = [L.AllPopulation];
scores = L.AllScores;

if isfield(L, 'InitialPopulationd')
    valid_idx = 1:2:size(in_data,1);
    in_data = in_data(valid_idx,:);
    scores = scores(valid_idx);
end

% Not enough data
if size(in_data, 1) < 2
    return;
end

max_score = max(scores(:));
if max_score > 1
    scores = scores / max_score;
end

pairDists = pdist(in_data, 'euclidean');

Y = cmdscale(pairDists, 2); % Project pairDists to a 2 Dimensional space

% Projection must have at least 2 dimensions to be drawn on a plane,
% usually this means that all the input points have the same values
if size(Y, 2) ~= 2
    return;
end

%% Plot the data
% Create a new figure
if isBatchMode()
    fig_h = figure('Visible', 'off');
else
    fig_h = figure('Position', [0 28 570 422]);
end

% Increase figure resolution
fig_h.Position = fig_h.Position * 2;

popSize = L.PopulationSize;
num_iterations = size(in_data, 1) / popSize;
min_idx = [0, 0];
min_scores = [0, 0];

offset = 0;

%% Plot once to get axis limits
scatter(Y(:, 1), Y(:,2));
x_axis_lim = xlim();
y_axis_lim = ylim();

% Circle radius scale is proportional to the axis size
rscale = mean(diff(x_axis_lim) + diff(y_axis_lim))/100;
line_width = 1;

%% Simple case with one iteration only
if num_iterations == 1
    i = 1;
    
    clf(fig_h);
    set(groot, 'CurrentFigure', fig_h);
    
    hold on;
    xlim(x_axis_lim);
    ylim(y_axis_lim);
    
    % Do hidden plots to get the colors right in the legend
    hl1 = plot(inf, inf, 'go');
    hl2 = plot(inf, inf, 'bo');
    
    % 1st iteration population
    viscircles(Y(offset+1: popSize+offset, :), scores(i,:)*rscale, ...
        'Color','g', 'LineWidth', line_width);
    
    [min_scores(1), min_idx(1)] = min(scores(i,:));
    min_idx(1) = min_idx(1) + offset;
    
    % Best in 1st iteration
    viscircles(Y(min_idx(1),:), min_scores(1)*rscale, 'Color','r', ...
        'LineWidth', line_width);
    
    % Legend using only the handlers that we are interested in
    legend([hl1, hl2], 'Initial Population',  'Best Initial' , 'Location', ...
        'northoutside', 'Orientation','horizontal');
    hold off;
    
    istr = sprintf('%03d', i - 1);
    saveas(fig_h, [fig_save_path istr], 'tiff');
    saveas(fig_h, [fig_save_path istr], 'svg');
    return;
end

%% Do a plot
clf(fig_h);
set(groot, 'CurrentFigure', fig_h);

hold on;

% Set common limits so that visualization becomes easier
xlim(x_axis_lim);
ylim(y_axis_lim);

% Do hidden plots to get the colors right in the legend
hl1 = plot(inf, inf, 'go');
hl2 = plot(inf, inf, 'ro');
hl3 = plot(inf, inf, 'bo');

% ith iteration population
viscircles(Y, scores*rscale, 'Color','r', 'LineWidth', line_width);

% Best of ith iteration
viscircles(Y(1,:), scores(1)*rscale, 'Color','g', 'LineWidth', line_width);

% Line from best in ith iteration to best in ith + 1 iteration
plot(Y(:, 1), Y(:,2), '--r');

% Best in ith + 1 iteration
viscircles(Y(end,:), scores(end)*rscale, 'Color','b', 'LineWidth', line_width);

% Legend using only the handlers that we are interested in
legend([hl1, hl2, hl3], 'Initial', 'Intermediate','Final', ...
    'Location', 'best', 'Orientation', 'horizontal');
axis tight;
axis equal;
hold off;

saveas(fig_h, fig_save_path, 'tiff');
saveas(fig_h, fig_save_path, 'svg');
saveas(fig_h, fig_save_path, 'fig');

% Move svg files to a separate folder
mkdir(out_folder, 'svg');
movefile([fig_save_path '*.svg'], fullfile(out_folder, 'svg'));

end

