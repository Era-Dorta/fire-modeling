function maya_common_initialization( maya_send, ports, scene_name, ...
    fuel_type, num_goal, is_custom_shader, is_mr)
%MAYA_COMMON_INITIALIZATION Initialization for Maya instances
%   MAYA_COMMON_INITIALIZATION( MAYA_SEND, PORTS, SCENE_NAME, ...
%   FUEL_TYPE, NUM_GOAL )

if (is_custom_shader && ~is_mr)
    disp('Switching to Mental Ray because custom fire shader is selected');
    is_mr = true;
end

% Initialization of load and send functions, set Maya software renderer or
% Mental Ray renderer
load_hm_in_maya([], [], is_custom_shader);
send_render_cmd([], [], is_mr);

if numel(ports) > 1
    parfevalOnAll(gcp, @load_hm_in_maya, 0, [], [], is_custom_shader);
    parfevalOnAll(gcp, @send_render_cmd, 0, [], [], is_mr);
end

for i=1:numel(ports)
    disp(['Loading scene in Maya:' num2str(ports(i))]);
    % Set project to fire project directory
    cmd = 'setProject \""$HOME"/maya/projects/fire\"';
    maya_send{i}(cmd, 0);
    
    % Open our test scene
    cmd = ['file -open -force \"scenes/' scene_name '.ma\"'];
    maya_send{i}(cmd, 0);
    
    % Set random seed for reproducibility in Maya, it doesn't affect the
    % Maya Software renderer
    cmd = 'seed(0)';
    maya_send{i}(cmd, 0);
    
    % Load the Maya data plugin
    cmd = 'loadPlugin \"SaveFireDataPlugin\"';
    maya_send{i}(cmd, 0);
    
    if is_custom_shader
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
    else
        % Temperatures will be overwriten by the nCache when using the Maya
        % shader, causing all the renders to be exactly the same
        cmd = 'setAttr \"Flame:flameShape.loadTemperature\" 0';
        maya_send{i}(cmd, 0);
    end
    
    % Deactive all but the first camera if there is more than one goal
    % image
    for j=2:num_goal
        cmd = ['setAttr \"camera' num2str(j) 'Shape.renderable\" 0'];
        maya_send{i}(cmd, 0);
    end
end

if ~is_custom_shader
    disp('Deactivated nCache for fluid temperature in Maya');
end

end

