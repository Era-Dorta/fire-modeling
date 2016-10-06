function [stop] = icm_restore_raw_file(x, optimValues, state, maya_send, ...
    init_heat_map, output_img_folder)
%ICM_RESTORE_RAW_FILE Loads raw file in maya
%
%   See also do_gradient_solve
stop = false;

if strcmp(state, 'init')
    if exist(output_img_folder, 'dir') ~= 7
        mkdir(output_img_folder);
    end
    load_file();
    return;
end

if strcmp(state, 'iter')
    load_file();
end

    function load_file()
        init_heat_map.v = x';
        
        if optimValues.do_temperature
            name_str = 'temperature';
        else
            name_str = 'density';
        end
        
        heat_map_path = fullfile( output_img_folder, [name_str '-' ...
            num2str(optimValues.iteration) '.raw']);
        
        save_raw_file(heat_map_path, init_heat_map);
        
        if optimValues.do_temperature
            for i=1:numel(maya_send)
                load_hm_in_maya(heat_map_path, maya_send{i});
            end
        else
            for i=1:numel(maya_send)
                load_density_in_maya(heat_map_path, maya_send{i});
            end
        end
    end

end