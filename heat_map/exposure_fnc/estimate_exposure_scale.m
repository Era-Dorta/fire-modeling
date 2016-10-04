function [ best_exposure, f_val ] = estimate_exposure_scale( maya_send, opts, init_heat_map, ...
    fitness_fnc, output_img_folder, out_dir, num_goal, use_mean_t)
%ESTIMATE_EXPOSURE_SCALE Estimate best exposure for heat map
%   [ BEST_EXPOSURE ] = ESTIMATE_EXPOSURE_SCALE( MAYA_SEND, OPTS, INIT_HEAT_MAP, ...
%    FITNESS_FNC, OUTPUT_IMG_FOLDER)

if ~isempty(opts.exposure_scales_range) && opts.is_custom_shader
        
    if use_mean_t
        init_heat_map.v(:) = mean([opts.LB, opts.UB]);
    end
    
    shape_name = 'mia_exposure_photographic1.cm2_factor';
    
    % Save the render images in this folder
    mkdir(out_dir);
    
    k0 = log10(opts.exposure_scales_range(1));
    k1 = log10(opts.exposure_scales_range(2));
    
    k_samples = linspace(k0, k1, opts.n_exposure_scale);
    
    f_val = zeros(1, numel(k_samples));
    
    % Loop in a logarithmic scale for the samples
    for i=1:numel(k_samples)
        % Set the new scale
        opts.maya_new_exposure_scale = 10^k_samples(i);
        cmd = ['setAttr ' shape_name ' ' num2str( opts.maya_new_exposure_scale)];
        maya_send{1}(cmd, 0);
        
        % Evaluate the fitness function
        f_val(i) = fitness_fnc(init_heat_map.v');
        
        % Clear the cache of the fitness as it is saved with the same
        % temperature
        if opts.use_cache
            clear_cache();
        end
        
        % Move the render image to the save folder
        for k=1:num_goal
            kstr = num2str(k);
            movefile(fullfile(output_img_folder, ['current1-Cam' kstr '.tif']), ...
                fullfile(out_dir, [num2str(i, '%03d') '-exposure-' ...
                num2str(opts.maya_new_exposure_scale) '-Cam' kstr '.tif']));
        end
    end
    
    % Get the best exposure scale, set it and return the value
    [~, i] = min(f_val);
    
    opts.maya_new_exposure_scale = 10^k_samples(i);
    
    cmd = ['setAttr ' shape_name ' ' num2str( opts.maya_new_exposure_scale)];
    for i=1:numel(maya_send)
       maya_send{i}(cmd, 0);
    end
    
    best_exposure = opts.maya_new_exposure_scale;
    
else
    best_exposure = [];
    f_val = [];
end

end

