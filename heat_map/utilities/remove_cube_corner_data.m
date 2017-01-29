function [ out_volume ] = remove_cube_corner_data( in_volume, remove_size)
if nargin == 1
    remove_size = 0.2;
end

if remove_size >= 0.5
    error('Remove size must be {0,0.5}');
end

box_size = in_volume.size*remove_size;

x0 = 1;
x1 = box_size(1);
x2 = in_volume.size(1);

y0 = 1;
y1 = box_size(2);
y2 = in_volume.size(2);

z0 = 1;
z1 = box_size(3);
z2 = in_volume.size(3);

out_volume = in_volume;

find_indices_in_bbox([x0, y0, z0], [x1, y1, z1]);
find_indices_in_bbox([x2-x1, y0, z0], [x2, y1, z1]);
find_indices_in_bbox([x0, y0, z2-z1], [x1, y1, z2]);
find_indices_in_bbox([x2-x1, y0, z2-z1], [x2, y1, z2]);
find_indices_in_bbox([x0, y2-y1, z0], [x1, y2, z1]);
find_indices_in_bbox([x2-x1, y2-y1, z0], [x2, y2, z1]);
find_indices_in_bbox([x0, y2-y1, z2-z1], [x1, y2, z2]);
find_indices_in_bbox([x1, y2-y1, z2-z1], [x2, y2, z2]);

% Uncomment to plot the boxes and the output
%plot_boxes(in_volume);
%plot_boxes(out_volume);

    function find_indices_in_bbox(min_bbox, max_bbox)
        to_del = [];
        for i=1:out_volume.count
            if all(out_volume.xyz(i,:) <= max_bbox) && all(out_volume.xyz(i,:) >= min_bbox)
                to_del = [to_del, i];
            end
        end
        
        out_volume.count = out_volume.count - length(to_del);
        out_volume.xyz(to_del,:) = [];
        out_volume.v(to_del,:) = [];
    end

    function plot_boxes(volume)
        plotHeatMap(volume);
        hold on;
        plotBbox([x0, y0, z0], [x1, y1, z1],'g', 0.2);
        plotBbox([x2-x1, y0, z0], [x2, y1, z1],'g', 0.2);
        plotBbox([x0, y0, z2-z1], [x1, y1, z2],'g', 0.2);
        plotBbox([x2-x1, y0, z2-z1], [x2, y1, z2],'g', 0.2);
        plotBbox([x0, y2-y1, z0], [x1, y2, z1],'g', 0.2);
        plotBbox([x2-x1, y2-y1, z0], [x2, y2, z1],'g', 0.2);
        plotBbox([x0, y2-y1, z2-z1], [x1, y2, z2],'g', 0.2);
        plotBbox([x2-x1, y2-y1, z2-z1], [x2, y2, z2],'g', 0.2);
        hold off;
    end
end
