function [ error ] = heat_map_fitness_order_float_par( heat_map_order, heat_map_v, xyz, whd, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, maya_send, ...
    num_goal, prior_fncs, prior_weights, color_space)

% Sort the float indices to get usable ones
for i=1:size(heat_map_order, 1)
    [~, heat_map_order(i,:)] = sort(heat_map_order(i,:));
end

% Render the heat maps and evaluate error
error = heat_map_fitness_order_par( heat_map_order, heat_map_v, xyz, whd, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, maya_send, ...
    num_goal, prior_fncs, prior_weights, color_space);
end