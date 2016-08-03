function [ best_density, f_val ] = estimate_density_scale( maya_send, opts, init_heat_map, ...
    fitness_fnc, output_img_folder, num_goal)
%ESTIMATE_DENSITY_SCALE Estimate best density for heat map
%   [ BEST_DENSITY ] = ESTIMATE_DENSITY_SCALE( MAYA_SEND, OPTS, INIT_HEAT_MAP, ...
%    FITNESS_FNC, OUTPUT_IMG_FOLDER)

if opts.is_mr == true
    % Save the render images in this folder
    out_dir = fullfile(output_img_folder, 'density-estimates');
    mkdir(out_dir);
    
    j = 1;
    f_val = [];
    
    % Loop for density_scales_range(1) to density_scales_range(2) using the
    % given step size
    i = opts.density_scales_range(1);
    while i <= opts.density_scales_range(2)
        % Set the new scale
        opts.maya_new_density_scale = i;
        maya_set_custom_parameters(maya_send, opts);
        
        % Evaluate the fitness function
        f_val(end+1) = fitness_fnc(init_heat_map.v');
        
        % Clear the cache of the fitness as it is saved with the same
        % temperature
        clear_cache();
        
        % Move the render image to the save folder
        for k=1:num_goal
            kstr = num2str(k);
            movefile(fullfile(output_img_folder, ['current1-Cam' kstr '.tif']), ...
                fullfile(out_dir, [num2str(j, '%03d') '-density-' num2str(i) ...
                '-Cam' kstr '.tif']));
        end
        
        i = i * opts.density_scale_inc;
        j = j + 1;
    end
    
    % Get the best density scale, set it and return the value
    [~, i] = min(f_val);
    
    opts.maya_new_density_scale = opts.density_scales_range(1) * ...
        opts.density_scale_inc^(i - 1);
    
    maya_set_custom_parameters(maya_send, opts);
    
    best_density = opts.maya_new_density_scale;
else
    best_density = [];
    f_val = [];
end

end

