function send_render_cmd(maya_send, cam_num, set_mental_ray)
%SEND_RENDER_CMD Sends a render command to Maya
%   SEND_RENDER_CMD([], [], SET_MENTAL_RAY) Initialization call,
%   SET_MENTAL_RAY is a boolean variable, true if rendering with Mental
%   Ray, false if using Maya software render. Must be called at least once.
%
%   SEND_RENDER_CMD(MAYA_SEND) Send render command, do NOT use this version
%   if Mental Ray was set to false.
%
%   SEND_RENDER_CMD(MAYA_SEND, CAM_NUM) Send render command, CAM_NUM is a
%   string with a positive integer, the rendered image will be from camera
%   CAM_NUM, if Mental Ray was set to true CAM_NUM is ignored and the first
%   renderable camera will be used.

persistent is_mental_ray

if nargin() == 3
    is_mental_ray = set_mental_ray;
    return;
end

if is_mental_ray
    cmd = 'Mayatomr -verbosity 2 -render -renderVerbosity 2';
    maya_send(cmd, 1);
else
    cmd = ['render camera' cam_num];
    maya_send(cmd, 0);
end

end