function [stop] = grad_estimate_exposure_scale(x, optimValues, state, ...
    maya_send, opts, init_heat_map, fitness_fnc, output_img_folder, num_goal)
%GRAD_ESTIMATE_EXPOSURE_SCALE Exposure estimate for Gradient Solver
%
%   See also do_gradient_solve
stop = false;

if strcmp(state,'iter')
    init_heat_map.v = x';
    out_dir = fullfile(output_img_folder, 'exposure-estimates', ['iter-' ...
        num2str(optimValues.iteration + 1)]);
    
    [best_density, f_val] = estimate_exposure_scale( maya_send, opts, init_heat_map, ...
        fitness_fnc, output_img_folder, out_dir, num_goal, false);
    
    if strcmp(opts.options.Display, 'iter')
        disp(['Best exposure scale ' num2str(best_density) ', fval '  ...
            num2str(min(f_val))]);
    end
end

end
