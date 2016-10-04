function [stop, out_exposure] = grad_estimate_exposure_scale(x, optimValues, state, ...
    maya_send, opts, init_heat_map, fitness_fnc, output_img_folder, num_goal)
%GRAD_ESTIMATE_EXPOSURE_SCALE Exposure estimate for Gradient Solver
%
%   See also do_gradient_solve
persistent EXPOSURE FVAL
stop = false;

if strcmp(state,'iter')
    options = opts.options;
    if optimValues.iteration == 0
        EXPOSURE = optimValues.exposure;
        FVAL = optimValues.fexposure;
    else
        init_heat_map.v = x';
        out_dir = fullfile(output_img_folder, 'exposure-estimates', ['iter-' ...
            num2str(optimValues.iteration + 1)]);        
        
        options.GenExposureStd = options.GenExposureStd - options.GenExposureStd * ...
            optimValues.iteration / options.MaxIterations;
        exposure_samples = normrnd(EXPOSURE, options.GenExposureStd, 1, opts.n_exposure_scale);
        
        [out_exposure, f_val] = estimate_exposure_with_range( maya_send, opts, init_heat_map, ...
            fitness_fnc, output_img_folder, out_dir, num_goal, exposure_samples);
        f_val = min(f_val);
        
        if f_val < FVAL
            EXPOSURE = out_exposure;
            FVAL = f_val;
        end
    end
    
    if strcmp(options.Display, 'iter')
        disp(['Best exposure scale ' num2str(EXPOSURE) ', fval '  ...
            num2str(FVAL)]);
    end
    
end

end
