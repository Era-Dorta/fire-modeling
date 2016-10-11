function [ best_exposure, f_val ] = estimate_exposure_scale_initial(  ...
    maya_send, opts, init_heat_map, fitness_fnc, output_img_folder, ...
    out_dir, num_goal, use_mean_t, use_mean_d)
%ESTIMATE_EXPOSURE_SCALE_INITIAL Estimate best exposure for heat map
%   [ BEST_EXPOSURE ] = ESTIMATE_EXPOSURE_SCALE_INITIAL( MAYA_SEND, OPTS, INIT_HEAT_MAP, ...
%    FITNESS_FNC, OUTPUT_IMG_FOLDER)

if ~isempty(opts.exposure_scales_range) && opts.is_custom_shader
    disp('Estimating initial exposure factor');
    
    if use_mean_d
        raw_folder = fullfile(output_img_folder, 'temp-raw-files');
        if exist(raw_folder, 'dir') ~= 7
            mkdir(raw_folder);
        end
        heat_map_path = fullfile(raw_folder, 'density-for-exposure-estimate-initial.raw');
        init_heat_map.v(:) = mean([opts.LBd, opts.UBd]);
        save_raw_file(heat_map_path, init_heat_map);
        for i=1:numel(maya_send)
            load_density_in_maya(heat_map_path, maya_send{i});
        end
    end
    
    if use_mean_t
        init_heat_map.v(:) = mean([opts.LB, opts.UB]);
    end
    
    k0 = log10(opts.exposure_scales_range(1));
    k1 = log10(opts.exposure_scales_range(2));
    
    % Log scale for the samples, as it is the initial estimate, sample
    % twice as much to provide better coverage
    k_samples = 10.^linspace(k0, k1, opts.n_exposure_scale * 2);
    
    [best_exposure, f_val] = estimate_exposure_with_range( maya_send, ...
        opts, init_heat_map, fitness_fnc, output_img_folder, out_dir, ...
        num_goal, k_samples);
    
    disp(['Exposure factor is ' num2str(best_exposure)]);
else
    best_exposure = [];
    f_val = [];
end

end

