function [ best_density, f_val, density_norm ] = estimate_density_scale_initial(  ...
    maya_send, opts, init_heat_map, fitness_fnc, output_img_folder, ...
    out_dir, num_goal, use_mean_t)
%ESTIMATE_DENSITY_SCALE_INITIAL Estimate best density for heat map
%   [ BEST_DENSITY ] = ESTIMATE_DENSITY_SCALE_INITIAL( MAYA_SEND, OPTS, INIT_HEAT_MAP, ...
%    FITNESS_FNC, OUTPUT_IMG_FOLDER)

if ~isempty(opts.density_scales_range)
    disp('Estimating initial scale factor');
    
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
    
    if use_mean_t
        init_heat_map.v(:) = mean([opts.LB, opts.UB]);
    end
    
    k0 = log10(opts.density_scales_range(1));
    k1 = log10(opts.density_scales_range(2));
    
    % Log scale for the samples, as it is the initial estimate, sample
    % twice as much to provide better coverage
    k_samples = 10.^linspace(k0, k1, opts.n_density_scale * 2);
    
    [best_density, f_val] = estimate_density_with_range( maya_send, ...
        opts, init_heat_map, fitness_fnc, output_img_folder, out_dir, ...
        num_goal, k_samples);
    
    disp(['Density factor is ' num2str(best_density)]);
else
    best_density = [];
    f_val = [];
    density_norm = [];
end

end

