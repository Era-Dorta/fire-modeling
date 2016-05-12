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

hold on;

% Plot initial population
offset = 0;
current_size = size(L.InitialPopulation, 1);
scatter(Y(1: current_size + offset, 1), Y(1: current_size + offset,2), 'gx');

% Plot final population
offset = offset + current_size;
current_size = size(L.FinalPopulation, 1);
scatter(Y(offset+1: current_size+offset, 1), Y(offset+1:current_size+offset,2), 'bx');

% Plot the best per generation
offset = offset + current_size;
current_size = size(L.BestPopGen, 1);

% Start with a star
plot(Y(offset+1, 1), Y(offset+1,2), '*r');

% Line with markers from second to final
plot(Y(offset+2:current_size+offset, 1), Y(offset+2:current_size+offset,2), '--or');

legend('Initial Population', 'Final Population', ...
    'Optimization Path Start Point', 'Optimization Path');

% Line from start to next
plot(Y(offset+1:offset+2, 1), Y(offset+1:offset+2,2), '--r');

hold off;

%% Save the figures
print(fig_h, fig_save_path, '-dtiff');
saveas(fig_h, fig_save_path, 'svg');
end

