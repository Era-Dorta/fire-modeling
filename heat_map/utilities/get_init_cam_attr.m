function [cam_attr] = get_init_cam_attr(opts)
    cam_attr = [opts.cam_t(1:3), opts.cam_r(1:3), opts.cam_focal_length(1)];
    j = 4;
    for i=2:numel(opts.goal_img_path)
        cam_attr = [cam_attr, opts.cam_t(j:j+2), opts.cam_r(j:j+2), opts.cam_focal_length(i)];
        j = j + 3;
    end
end