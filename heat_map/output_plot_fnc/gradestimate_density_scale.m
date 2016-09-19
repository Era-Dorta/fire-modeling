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
    
    [best_density, f_val, density_norm] = estimate_density_scale( maya_send, opts, init_heat_map, ...
        fitness_fnc, output_img_folder, out_dir, num_goal, false);
    
    if strcmp(opts.options.Display, 'iter')
        disp(['Best density scale ' num2str(best_density) ', fval '  ...
            num2str(min(f_val)) ', density norm ' num2str(density_norm)]);
    end
end

end
