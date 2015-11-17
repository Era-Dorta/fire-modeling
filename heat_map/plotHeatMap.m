function plotHeatMap( heat_map )
% Plots the heat map given as parameter
% Do a simple color mapping from the temperatures
colors = heat_map.v;
colors = colors / max(colors);
colors = [colors, zeros(heat_map.count, 1), zeros(heat_map.count, 1)];
figure;
hold on;
set(gca,'xlim', [0, heat_map.size(1)]);
set(gca,'ylim', [0, heat_map.size(2)]);
set(gca,'zlim', [0, heat_map.size(3)]);
xlabel('x');
ylabel('y');
zlabel('z');
view(150,-10)
scatter3(heat_map.xyz(:,1), heat_map.xyz(:,2), heat_map.xyz(:,3), 1, colors);
hold off;
end

