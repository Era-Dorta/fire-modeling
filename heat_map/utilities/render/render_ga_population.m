function render_ga_population( population, opts, maya_send, num_goal, ...
    init_heat_map, output_img_folder_name, msg, par_offset)
%RENDER_GA_POPULATION Renders GA inital and final population
%   RENDER_GA_POPULATION( POPULATION, OPTS, MAYA_SEND, NUM_GOAL, ...
%    INIT_HEAT_MAP, OUTPUT_IMG_FOLDER_NAME, MSG )

for i=1:num_goal
    istr = num2str(i);
    
    output_folder = fullfile(opts.scene_img_folder, output_img_folder_name, ...
        [msg 'Cam' istr]);
    
    % Create directory for the render images
    if (~exist(output_folder, 'dir'))
        mkdir(output_folder);
    end
    
    output_folder_rel = fullfile(output_img_folder_name, [msg 'Cam' istr]);
    
    % Active current camera
    if(num_goal > 1)
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 1'];
        maya_send(cmd, 0);
    end
    
    render_heat_maps( population, init_heat_map.xyz, init_heat_map.size, ...
        opts.scene_name, opts.scene_img_folder, output_folder_rel, ...
        maya_send, par_offset, istr);
    
    % Deactive current camera
    if(num_goal > 1)
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 0'];
        maya_send(cmd, 0);
    end
end

end

