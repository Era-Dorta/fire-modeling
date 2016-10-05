function load_density_in_maya(density_path, maya_send, set_mental_ray)
%LOAD_DENSITY_IN_MAYA Load a heat_map.raw file in Maya
%   LOAD_DENSITY_IN_MAYA([], [], SET_MENTAL_RAY) Initialization call,
%   SET_MENTAL_RAY is a boolean variable, true if using Mental Ray custom
%   shader, false otherwise. Must be called at least once.
%
%   LOAD_DENSITY_IN_MAYA(HEAT_MAP_PATH, MAYA_SEND) HEAT_MAP_PATH string path is
%   loaded into the Maya using the MAYA_SEND function handle.

persistent is_mental_ray

if nargin() == 3
    is_mental_ray = set_mental_ray;
    return;
end

if nargin() ~= 2
    error('After initialization, call syntax is with 2 arguments');
end

load_density_raw_in_maya(density_path, maya_send, is_mental_ray);

end