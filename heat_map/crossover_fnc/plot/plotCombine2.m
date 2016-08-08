function child = plotCombine2( parent1, parent2, seed )
%PLOTCOMBINE2 Plot result of combineHeatMap2point
%   CHILD = PLOTCOMBINE2( PARENT1, PARENT2, SEED ) Plots the heat maps
%   PARENT1, PARENT2, and CHILD.
%   CHILD = combineHeatMap2point(PARENT1, PARENT2, SEED)
%
%   CHILD = PLOTCOMBINE2( PARENT1, PARENT2 ) Same as above with SEED = 1
%
%   CHILD = PLOTCOMBINE2() Same as above with PARENT1 = '~/h0.raw' and
%   PARENT2 = '~/h1.raw'
%
%   See also combineHeatMap2point

if nargin == 0
    parent1 = read_raw_file('~/h0.raw');
    parent2 = read_raw_file('~/h1.raw');
    seed = 1;
end

if nargin == 2
    seed = 1;
end

% Assuming both parents have the same xyz
bboxmin = min(parent1.xyz);
bboxmax = max(parent1.xyz);

child = parent1;

% Execute and catch the standard output in text_out
[text_out, child.v] = evalc(['combineHeatMap2point(parent1.xyz, parent1.v,' ...
    'parent2.v, bboxmin, bboxmax, 0.5, seed);']);

if(strcmp(text_out,''))
    disp('Define PRINT_INFO in combineHeatMap2point and run again');
    return;
end

hm = {parent1, parent2, child};

% Get only the last try
text_out = strsplit(text_out, 'Total size\n');
disp(['Needed ' num2str(numel(text_out) - 1) ' tries to get good indices']);
text_out = [sprintf('Total size\n') text_out{end}];

text_out = strsplit(text_out, '\n');

num_boxes = (numel(text_out) - 10)/3;
v_min = zeros(num_boxes+1, 3);
v_max = zeros(num_boxes+1, 3);

% The bounding box that covers all the data
v_min(1,:) = str2num(text_out{2});
v_max(1,:) = str2num(text_out{3});

% The two points selected for the two point crossover
ori_idx = zeros(2, 3);
ori_idx(:,1) = str2num(text_out{5})';
ori_idx(:,2) = str2num(text_out{7})';
ori_idx(:,3) = str2num(text_out{9})';

% The bounding box/es that covers the space between the two crossover
% points
j = 11;
for i=1:num_boxes
    v_min(i+1,:) = str2num(text_out{j});
    v_max(i+1,:) = str2num(text_out{j+1});
    j = j + 3;
end

% Switch y,z for plotting
v_min = [v_min(:,1), v_min(:,3), v_min(:,2)];
v_max = [v_max(:,1), v_max(:,3), v_max(:,2)];
ori_idx = [ori_idx(:,1), ori_idx(:,3), ori_idx(:,2)];

% All data bounding box in blue, the others in green, max of 8 boxes
plot_c = 'bgggggggg';

names = {'parent1', 'parent2', 'child'};

for i=1:3
    
    plotHeatMap(hm{i});
    
    fig = gcf;
    fig.Name = names{i};
    
    hold on;
    
    % Start and end point
    plot3(ori_idx(1,1), ori_idx(1,2), ori_idx(1,3), 'bo');
    plot3(ori_idx(2,1), ori_idx(2,2), ori_idx(2,3), 'rx');
    
    % All bounding boxes
    for j=1:size(v_min, 1)
        plotBbox(v_min(j,:), v_max(j,:), plot_c(j));
    end
    
    alpha(0.2);
    view(3);
    
    legend('Heat Values', 'BBox start', 'BBox end', 'Space limits', 'Combine BBox');
    hold off;
end

end

