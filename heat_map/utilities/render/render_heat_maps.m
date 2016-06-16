function render_heat_maps( heat_map_v, xyz, whd, scene_name, scene_img_folder, ...
    output_folder, maya_send, name_offset, cam_num)
%RENDER_HEAT_MAPS Renders heat maps in a folder
%    RENDER_HEAT_MAPS( HEAT_MAP_V, XYZ, WHD, SCENE_NAME, SCENE_IMG_FOLDER, ...
%     OUTPUT_FOLDER, MAYA_SEND)

for pop=1:size(heat_map_v, 1)
    
    popstr = num2str(pop + name_offset);
    
    %% Save the heat_map in a file
    heat_map_path = fullfile(scene_img_folder, output_folder, ...
        ['heat-map' popstr '.raw']);
    volumetricData = struct('xyz', xyz, 'v', heat_map_v(pop, :)', 'size', whd, ...
        'count', size(xyz,1));
    save_raw_file(heat_map_path, volumetricData);
    
    %% Set the heat map file as temperature file
    % Either set the full path or set the file relative maya path for
    % temperature_file_first and force frame update to run
    load_hm_in_maya(heat_map_path, maya_send);
    
    %% Set the folder and name of the render image
    cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
    cmd = [cmd fullfile(scene_name, output_folder, ['fireimage' popstr]) '\"'];
    maya_send(cmd, 0);
    
    %% Render the image
    % This command only works on Maya running in batch mode, if running with
    % the GUI, use Mayatomr -preview. and then save the image with
    % $filename = "Path to save";
    % renderWindowSaveImageCallback "renderView" $filename "image";
    send_render_cmd(maya_send, cam_num);
end

end
