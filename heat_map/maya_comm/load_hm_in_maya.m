function load_hm_in_maya(heat_map_path, maya_send, set_mental_ray)
%LOAD_HM_IN_MAYA Load a heat_map.raw file in Maya
%   LOAD_HM_IN_MAYA([], [], SET_MENTAL_RAY) Initialization call,
%   SET_MENTAL_RAY is a boolean variable, true if using Mental Ray custom
%   shader, false otherwise. Must be called at least once.
%
%   LOAD_HM_IN_MAYA(HEAT_MAP_PATH, MAYA_SEND) HEAT_MAP_PATH string path is
%   loaded into the Maya using the MAYA_SEND function handle.

persistent is_mental_ray

if nargin() == 3
    is_mental_ray = set_mental_ray;
    return;
end

if nargin() ~= 2
    error('After initialization, call syntax is with 2 arguments');
end

if is_mental_ray
    cmd = 'setAttr -type \"string\" fire_volume_shader.temperature_file \"';
    cmd = [cmd '$HOME/' heat_map_path(3:end) '\"'];
    maya_send(cmd, 0);
else
    cmd = 'loadFireData \"Flame:flameShape\" ';
    cmd = [cmd '\"$HOME/' heat_map_path(3:end) '\"'];
    maya_send(cmd, 0);
end

end

