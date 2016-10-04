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
    
    maya_par_eval();
    
    % Get the best exposure scale, set it and return the value
    [~, i] = min(f_val);
    
    best_exposure = 10^k_samples(i);
    
    cmd = ['setAttr ' shape_name ' ' num2str( best_exposure)];
    for i=1:numel(maya_send)
        maya_send{i}(cmd, 0);
    end
    
else
    best_exposure = [];
    f_val = [];
end

    function maya_par_eval
        num_samples = numel(k_samples);
        num_maya = min(numel(maya_send), num_samples);
        x = repmat(init_heat_map.v', num_maya, 1);
        
        for j=1:num_maya:num_samples
            l = j:min(j+num_maya-1, num_samples);
            
            for c_maya=1:numel(l)
                new_exposure = 10^k_samples(l(c_maya));
                cmd = ['setAttr ' shape_name ' ' num2str(new_exposure)];
                maya_send{c_maya}(cmd, 0);
            end
            
            f_val(l) = fitness_fnc(x(1:numel(l),:));
            
            if num_maya == 1
                % With one maya instance move each render image to
                % the save folder
                for k=1:num_goal
                    kstr = num2str(k);
                    movefile(fullfile(output_img_folder, ['current1-Cam' kstr '.tif']), ...
                        fullfile(out_dir, [num2str(j, '%03d') '-exposure-' ...
                        num2str(new_exposure) '-Cam' kstr '.tif']));
                end
            end
            
            % Clear the cache of the fitness as it is saved with the same
            % temperature
            if opts.use_cache
                clear_cache();
            end
        end
        
        if num_maya > 1
            % With parallel evaluation we can only move the best image as
            % the other are deleted inside the fitness_fnc
            [~, j] = min(f_val);
            for k=1:num_goal
                kstr = num2str(k);
                movefile(fullfile(output_img_folder, ['current1-Cam' kstr '.tif']), ...
                    fullfile(out_dir, [num2str(j, '%03d') '-exposure-' ...
                    num2str(10^k_samples(j)) '-Cam' kstr '.tif']));
            end
        end
        
    end

end

