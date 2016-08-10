function plotHeatMap( heat_map, scale_factor )
%PLOTHEATMAP Plots the heat map given as parameter
%   PLOTHEATMAP( HEAT_MAP ) Plot the heat map
%
%   PLOTHEATMAP( HEAT_MAP, SCALE_FACTOR ) Plot the heat map, HEAT_MAP.V are
%   rescaled before plotting HEAT_MAP.V = HEAT_MAP.V * SCALE_FACTOR

% Do a simple color mapping from the temperatures
colors = heat_map.v;

% Apply scale factor if given, also rescale if temperatures are too high,
% as we are using their values directly and max RGB color is 1
if nargin == 2 || max(colors) > 1
    
    if nargin == 1
        scale_factor = 1 / max(colors);
    end
    
    colors = colors * scale_factor;
end

colors = [colors, zeros(heat_map.count, 1), zeros(heat_map.count, 1)];

figure;
hold on;

scatter3(heat_map.xyz(:,1), heat_map.xyz(:,3), heat_map.xyz(:,2), 1, colors);

set(gca,'xlim', [0, heat_map.size(1)]);
set(gca,'ylim', [0, heat_map.size(2)]);
set(gca,'zlim', [0, heat_map.size(3)]);

xlabel('x');
ylabel('z');
zlabel('y');

view(-37,20)

hold off;
end

