function visualize_score_space( data_file, fig_save_path )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%% Load data and compute multidimensional scaling
L = load(data_file);

in_data = [L.InitialPopulation; L.FinalPopulation; L.BestPopGen];

pairDists = pdist(in_data, 'euclidean');

Y = cmdscale(pairDists, 2); % Project pairDists to a 2 Dimensional space

%% Plot the data
% Create a new figure
if isBatchMode()
    fig_h = figure('Visible', 'off');
else
    fig_h = figure('Position', [1316 28 570 422]);
end

% First scatter text in legend appears as blue do to bug in Matlab 2015b,
% do a fake plot with the same color, save the handle and hide the plot
hl(1) = plot(1, 1, 'gx');
hl(1).Visible = 'off';

hold on;

% Plot initial population
offset = 0;
current_size = size(L.InitialPopulation, 1);
scatter(Y(1: current_size + offset, 1), Y(1: current_size + offset,2), 'gx');

% Plot final population
offset = offset + current_size;
current_size = size(L.FinalPopulation, 1);
hl(2) = scatter(Y(offset+1: current_size+offset, 1), Y(offset+1:current_size+offset,2), 'bx');

% Plot the best per generation
offset = offset + current_size;
current_size = size(L.BestPopGen, 1);

% Start with a star
hl(3) = plot(Y(offset+1, 1), Y(offset+1,2), '*r');

% Line from start to second
plot(Y(offset+1:offset+2, 1), Y(offset+1:offset+2,2), '--r');

% Line with markers from second to final
hl(4) = plot(Y(offset+2:current_size+offset, 1), Y(offset+2:current_size+offset,2), '--or');

% Legend using only the handlers that we are interested in
legend(hl, 'Initial Population', 'Final Population', ...
    'Optimization Path Start Point', 'Optimization Path');

hold off;

%% Save the figures
print(fig_h, fig_save_path, '-dtiff');
saveas(fig_h, fig_save_path, 'svg');
end

