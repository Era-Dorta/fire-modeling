function plotHeatMap( heat_map )
% Plots the heat map given as parameter
% Do a simple color mapping from the temperatures
colors = heat_map.v;
colors = colors / max(colors);
colors = [colors, zeros(heat_map.size, 1), zeros(heat_map.size,1)];
figure;
scatter3(heat_map.xyz(:,1), heat_map.xyz(:,2), heat_map.xyz(:,3), 1, colors);
end

