function [optimValues] = grad_estimate_exposure_scale(x, optimValues, state, ...
    maya_send, opts, init_heat_map, fitness_fnc, output_img_folder, num_goal)
%GRAD_ESTIMATE_EXPOSURE_SCALE Exposure estimate for Gradient Solver
%
%   See also do_gradient_solve

if strcmp(state,'iter')
    options = opts.options;
    init_heat_map.v = x';
    out_dir = fullfile(output_img_folder, 'exposure-estimates',  ...
        ['iter-' num2str(optimValues.iteration)]);
    
    options.GenExposureStd = options.GenExposureStd - options.GenExposureStd * ...
        optimValues.iteration / options.MaxIterations;
    exposure_samples = normrnd(optimValues.exposure, options.GenExposureStd, 1, opts.n_exposure_scale);
    exposure_samples = max([exposure_samples, optimValues.exposure], eps);
    
    [out_exposure, f_val] = estimate_exposure_with_range( maya_send, opts, init_heat_map, ...
        fitness_fnc, output_img_folder, out_dir, num_goal, exposure_samples);
    
    optimValues.fexposure = f_val(end);
    
    f_val = min(f_val);
    
    if f_val < optimValues.fexposure
        optimValues.exposure = out_exposure;
        optimValues.fexposure = f_val;
    end
    
    optimValues.funccount = optimValues.funccount + opts.n_exposure_scale;
end

end
