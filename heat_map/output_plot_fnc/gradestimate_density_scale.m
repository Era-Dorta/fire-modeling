function [stop] = gradestimate_density_scale(x, optimValues, state, ...
    maya_send, opts, init_heat_map, fitness_fnc, output_img_folder, num_goal)
%GRADSAVESCORES Save scores for Gradient Solver
%   [STOP] = GRADSAVESCORES(X, OPTIMVALUES, STATE, SAVE_PATH) To be used as
%   an output function for the gradient solver. It will append the scores
%   of the initial guess to SAVE_PATH, as well as the scores of the
%   best individual per iteration and the individual itself.
%
%   See also gradient
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
