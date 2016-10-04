function [ best_exposure, f_val ] = estimate_exposure_scale( maya_send, opts, init_heat_map, ...
    fitness_fnc, output_img_folder, out_dir, num_goal, use_mean_t)
%ESTIMATE_EXPOSURE_SCALE Estimate best exposure for heat map
%   [ BEST_EXPOSURE ] = ESTIMATE_EXPOSURE_SCALE( MAYA_SEND, OPTS, INIT_HEAT_MAP, ...
%    FITNESS_FNC, OUTPUT_IMG_FOLDER)

if ~isempty(opts.exposure_scales_range) && opts.is_custom_shader
    
    if use_mean_t
        init_heat_map.v(:) = mean([opts.LB, opts.UB]);
    end
    
    k0 = log10(opts.exposure_scales_range(1));
    k1 = log10(opts.exposure_scales_range(2));
    
    k_samples = linspace(k0, k1, opts.n_exposure_scale);
    
    [best_exposure, f_val] = estimate_exposure_with_range( maya_send, ...
        opts, init_heat_map, fitness_fnc, output_img_folder, out_dir, ...
        num_goal, k_samples);
    
else
    best_exposure = [];
    f_val = [];
end

end

