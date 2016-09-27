function child = plotCombine8( parent1, parent2)
%PLOTCOMBINE8 Plot result of combineHeatMap2point
%   CHILD = PLOTCOMBINE8( PARENT1, PARENT2) Plots the heat maps
%   PARENT1, PARENT2, and CHILD.
%
%   CHILD = PLOTCOMBINE8() Same as above with PARENT1 = '~/h0.raw' and
%   PARENT2 = '~/h1.raw'
%
%   See also combineHeatMap8
close all;
if nargin == 0
    parent1 = read_raw_file('~/h0.raw');
    parent1.v = parent1.v * 0.5;
    parent2 = read_raw_file('~/h1.raw');
    parent2.v = parent2.v * 1.5;
end

% Assuming both parents have the same xyz
bboxmin = min(parent1.xyz);
bboxmax = max(parent1.xyz);

child = parent1;

child.v = combineHeatMap8(parent1.xyz, parent1.v, parent2.v, bboxmin, ...
    bboxmax, 0.5);

hm = {parent1, parent2, child};

% Recreate the indices for the volumes
x0 = bboxmin(1);
x1 = (bboxmax(1) + bboxmin(1))/2;
x2 = bboxmax(1);
y0 = bboxmin(3);
y1 = (bboxmax(3) + bboxmin(3))/2;
y2 = bboxmax(3);
z0 = bboxmin(2);
z1 = (bboxmax(2) + bboxmin(2))/2;
z2 = bboxmax(2);

v_min = [x0, y0, z0;
    x1, y0, z0;
    x0, y0, z1;
    x1, y0, z1;
    x0, y1, z0;
    x1, y1, z0;
    x0, y1, z1;
    x1, y1, z1];

v_max = [x1, y1, z1;
    x2, y1, z1;
    x1, y1, z2;
    x2, y1, z2;
    x1, y2, z1;
    x2, y2, z1;
    x1, y2, z2;
    x2, y2, z2];

plot_c = {'bggbgbbg', 'gbbgbggb', 'bggbgbbg',};


names = {'parent1', 'parent2', 'child'};

for i=1:3
    
    plotHeatMap(hm{i}, 1/0.0162);
    
    fig = gcf;
    fig.Name = names{i};
    
    hold on;
    
    if i == 3
        % All bounding boxes
        for j=1:size(v_min, 1)
            plotBbox(v_min(j,:), v_max(j,:), plot_c{i}(j));
        end
    end
    
    alpha(0.2);
    axis equal; % Same units for all the axis
    %view(3);
    view(-56, 16);
    
    if i == 3
        legend('Heat Values', 'Parent 1', 'Parent 2');
    end
    
    hold off;
end

end

