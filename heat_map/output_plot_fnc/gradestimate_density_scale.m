function [stop] = gradestimate_density_scale(x, optimValues, state, ...
    maya_send, opts, init_heat_map, fitness_fnc, output_img_folder, num_goal)
%GRADESTIMATE_DENSITY_SCALE Density estimate for Gradient Solver
%
%   See also do_gradient_solve
stop = false;

if strcmp(state,'iter')
    init_heat_map.v = x';
    out_dir = fullfile(output_img_folder, 'density-estimates', ['iter-' ...
        num2str(optimValues.iteration + 1)]);
    
    k0 = log10(opts.density_scales_range(1));
    k1 = log10(opts.density_scales_range(2));
    
    k_samples = 10.^linspace(k0, k1, opts.n_density_scale);
    
    [best_density, f_val] = estimate_density_with_range( maya_send, ...
        opts, init_heat_map, fitness_fnc, output_img_folder, out_dir, ...
        num_goal, k_samples);
    
    if strcmp(opts.options.Display, 'iter')
        disp(['Best density scale ' num2str(best_density) ', fval '  ...
            num2str(min(f_val))]);
    end
end

end
