function [optimValues] = icm_estimate_density_scale(x, optimValues, state, ...
    maya_send, opts, init_heat_map, fitness_fnc, output_img_folder, num_goal)
%ICM_ESTIMATE_DENSITY_SCALE density estimate for ICM Solver
%
%   See also do_gradient_solve

if strcmp(state,'init')
    init_heat_map.v = x';
    
    density_folder = fullfile(output_img_folder, 'density-estimates', 'initial');
    if isempty(optimValues.density)
        [out_density, f_val] =  estimate_density_scale_initial( maya_send,  ...
            opts, init_heat_map, fitness_fnc, output_img_folder, ...
            density_folder, num_goal, false);
        
        optimValues.density = out_density;
    else
        % If a density is given just eval the fitness function at the given
        % value
        disp(['Eval previous frame density ' num2str(optimValues.density)]);
        density_samples = [optimValues.density];
        [~, f_val] = estimate_density_with_range( maya_send, opts, init_heat_map, ...
            fitness_fnc, output_img_folder, density_folder, num_goal, density_samples);
    end
    optimValues.fdensity = min(f_val);
    optimValues.funccount = optimValues.funccount + numel(f_val);
    return;
end

if strcmp(state,'iter')
    options = opts.options;
    init_heat_map.v = x';
    out_dir = fullfile(output_img_folder, 'density-estimates',  ...
        [state '-' num2str(optimValues.iteration)]);
    
    options.GenDensityStd = options.GenDensityStd - options.GenDensityStd * ...
        optimValues.iteration / options.MaxIterations;
    density_samples = normrnd(optimValues.density, options.GenDensityStd, 1, opts.n_density_scale);
    density_samples = max([density_samples, optimValues.density], eps);
    
    [out_density, f_val] = estimate_density_with_range( maya_send, opts, init_heat_map, ...
        fitness_fnc, output_img_folder, out_dir, num_goal, density_samples);
    
    optimValues.fdensity = f_val(end);
    
    f_val = min(f_val);
    
    if f_val < optimValues.fdensity
        optimValues.density = out_density;
        optimValues.fdensity = f_val;
    end
    
    optimValues.funccount = optimValues.funccount + opts.n_density_scale;
end

end