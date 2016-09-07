function load_density_raw_in_maya(raw_file_path, maya_send, is_custom_shader)
%LOAD_DENSITY_RAW_IN_MAYA Load a heat_map.raw file in Maya
%   LOAD_DENSITY_RAW_IN_MAYA(RAW_FILE_PATH, MAYA_SEND, IS_CUSTOM_SHADER)
%   HEAT_MAP_PATH string path is loaded into the Maya using the
%   MAYA_SEND function handle.

if is_custom_shader
    cmd = 'setAttr -type \"string\" fire_volume_shader.density_file \"';
    cmd = [cmd '$HOME/' raw_file_path(3:end) '\"'];
    maya_send(cmd, 0);
else
    cmd = 'loadFireData \"Flame:flameShape\" ';
    cmd = [cmd '\"$HOME/' raw_file_path(3:end) '\" -type \"density\"'];
    maya_send(cmd, 0);
end

end

