function [optimValues] = icm_density_estimate_exposure_scale(x, optimValues, state, ...
    maya_send, opts, init_heat_map, fitness_fnc, output_img_folder, num_goal)
%ICM_DENSITY_ESTIMATE_EXPOSURE_SCALE
fitness_fnc1 = @(x)fitness_fnc(x, optimValues.do_temperature);

[optimValues] = icm_estimate_exposure_scale(x, optimValues, state, ...
    maya_send, opts, init_heat_map, fitness_fnc1, output_img_folder, num_goal);

end