function maya_common_initialization( maya_send, ports, scene_name, ...
    fuel_type, num_goal, is_mr)
%MAYA_COMMON_INITIALIZATION Initialization for Maya instances
%   MAYA_COMMON_INITIALIZATION( MAYA_SEND, PORTS, SCENE_NAME, ...
%   FUEL_TYPE, NUM_GOAL )

% Initialization of load and send functions, set Maya software renderer or 
% Mental Ray renderer
load_hm_in_maya([], [], is_mr);
send_render_cmd([], [], is_mr);

for i=1:numel(ports)
    disp(['Loading scene in Maya:' num2str(ports(i))]);
    % Set project to fire project directory
    cmd = 'setProject \""$HOME"/maya/projects/fire\"';
    maya_send{i}(cmd, 0);
    
    % Open our test scene
    cmd = ['file -open -force \"scenes/' scene_name '.ma\"'];
    maya_send{i}(cmd, 0);
    
    if is_mr
        % Force a frame update, as batch rendering later does not do it, this
        % will fix any file name errors due to using the same scene on
        % different computers
        cmd = '\$ctime = \`currentTime -query\`; currentTime 1; currentTime \$ctime';
        maya_send{i}(cmd, 0);
        
        % Set the fuel type
        cmd = ['setAttr \"fire_volume_shader.fuel_type\" ' num2str(fuel_type)];
        maya_send{i}(cmd, 0);
        
        % Set the temperature scale to one, if scale and offset were not
        % set the upper and lower bounds could be violated
        cmd = 'setAttr \"fire_volume_shader.temperature_scale\" 1';
        maya_send{i}(cmd, 0);
        
        % Set offset to zero
        cmd = 'setAttr \"fire_volume_shader.temperature_offset\" 0';
        maya_send{i}(cmd, 0);
    end
    
    % Deactive all but the first camera if there is more than one goal
    % image
    for j=2:num_goal
        cmd = ['setAttr \"camera' num2str(j) 'Shape.renderable\" 0'];
        maya_send{i}(cmd, 0);
    end
end
end

