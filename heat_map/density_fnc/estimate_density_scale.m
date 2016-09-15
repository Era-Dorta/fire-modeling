function [ best_density, f_val, density_norm ] = estimate_density_scale( maya_send, opts, init_heat_map, ...
    fitness_fnc, output_img_folder, num_goal)
%ESTIMATE_DENSITY_SCALE Estimate best density for heat map
%   [ BEST_DENSITY ] = ESTIMATE_DENSITY_SCALE( MAYA_SEND, OPTS, INIT_HEAT_MAP, ...
%    FITNESS_FNC, OUTPUT_IMG_FOLDER)

if ~isempty(opts.density_scales_range)
    
    if ~isempty(opts.density_file_path)
        density_raw = read_raw_file(opts.density_file_path);
        density_norm = 1 / max(density_raw.v);
        if isinf(density_norm)
            error('Density file max value is zero');
        end
    else
        density_norm = 1;
        warning(['If no density file path is given, it is recommended that' ...
            ' the one already set is normalized']);
    end
    
    init_heat_map.v(:) = mean([opts.LB, opts.UB]);
    
    % Save the render images in this folder
    out_dir = fullfile(output_img_folder, 'density-estimates');
    mkdir(out_dir);
    
    k0 = log10(opts.density_scales_range(1));
    k1 = log10(opts.density_scales_range(2));
    
    k_samples = linspace(k0, k1, opts.n_density_scale);
    
    f_val = zeros(1, numel(k_samples));
    
    % Loop in a logarithmic scale for the samples
    for i=1:numel(k_samples)
        % Set the new scale
        opts.maya_new_density_scale = 10^k_samples(i) * density_norm;
        maya_set_custom_parameters(maya_send, opts);
        
        % Evaluate the fitness function
        f_val(i) = fitness_fnc(init_heat_map.v');
        
        % Clear the cache of the fitness as it is saved with the same
        % temperature
        clear_cache();
        
        % Move the render image to the save folder
        for k=1:num_goal
            kstr = num2str(k);
            movefile(fullfile(output_img_folder, ['current1-Cam' kstr '.tif']), ...
                fullfile(out_dir, [num2str(i, '%03d') '-density-' ...
                num2str(opts.maya_new_density_scale) '-Cam' kstr '.tif']));
        end
    end
    
    % Get the best density scale, set it and return the value
    [~, i] = min(f_val);
    
    opts.maya_new_density_scale = 10^k_samples(i) * density_norm;
    
    maya_set_custom_parameters(maya_send, opts);
    
    best_density = opts.maya_new_density_scale;
    
else
    best_density = [];
    f_val = [];
    density_norm = [];
end

end

