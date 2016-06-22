function render_single_hm( maya_send, num_cam, heat_map_path, output_path )
%RENDER_SINGLE_HM Render single heat map
%   RENDER_SINGLE_HM( MAYA_SEND, NUM_CAM, HEAT_MAP_PATH, OUTPUT_PATH )
%   Renders NUM_CAM (positive integer) images in OUTPUT_PATH (string),
%   using MAYA_SEND function handler, of the heat map located in
%   HEAT_MAP_PATH (string)

% Maya does not accept '~', transform explicitely to the absolute path
if(output_path(1) == '~')
    home = getenv('HOME');
    output_path = [home, output_path(2:end)];
end

load_hm_in_maya(heat_map_path, maya_send);

for i=1:num_cam
    istr = num2str(i);
    
    % Active current camera
    if(num_cam > 1)
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 1'];
        maya_send(cmd, 0);
    end
    
    % Set the folder and name of the render image
    cmd = ['setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix' ...;
        ' \"' output_path istr '\"'];
    maya_send(cmd, 0);
    
    % Render the image
    send_render_cmd(maya_send, istr);
    
    % Deactivate the current camera
    if(num_cam > 1)
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 0'];
        maya_send(cmd, 0);
    end
end
end

