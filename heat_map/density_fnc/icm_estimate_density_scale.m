function [optimValues] = icm_estimate_density_scale(x, optimValues, state, ...
    maya_send, opts, init_heat_map, fitness_fnc, output_img_folder, num_goal)
%ICM_ESTIMATE_DENSITY_SCALE density estimate for Gradient Solver
%
%   See also do_gradient_solve

if strcmp(state,'iter') && optimValues.iteration > 0
    options = opts.options;
    init_heat_map.v = x';
    out_dir = fullfile(output_img_folder, 'density-estimates',  ...
        ['iter-' num2str(optimValues.iteration)]);
    
    options.GenDensityStd = options.GenDensityStd - options.GenDensityStd * ...
        optimValues.iteration / options.MaxIterations;
    density_samples = normrnd(optimValues.density, options.GenDensityStd, 1, opts.n_density_scale);
    density_samples = max(density_samples, eps);
    
    [out_density, f_val] = estimate_density_with_range( maya_send, opts, init_heat_map, ...
        fitness_fnc, output_img_folder, out_dir, num_goal, density_samples);
    f_val = min(f_val);
    
    if f_val < optimValues.fdensity
        optimValues.density = out_density;
        optimValues.fdensity = f_val;
    end
    
    optimValues.funccount = optimValues.funccount + opts.n_density_scale;
end

end