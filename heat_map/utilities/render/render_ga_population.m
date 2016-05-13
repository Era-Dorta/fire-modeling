function render_ga_population( population, opts, maya_send, num_goal, ...
    init_heat_map, output_img_folder_name, msg )
%RENDER_GA_POPULATION Renders GA inital and final population
%   RENDER_GA_POPULATION( POPULATION, OPTS, MAYA_SEND, NUM_GOAL, ...
%    INIT_HEAT_MAP, OUTPUT_IMG_FOLDER_NAME, MSG )

disp(['Rendering the ' msg ' in ' opts.scene_img_folder ...
    output_img_folder_name msg 'Cam<d>' ]);

for i=1:num_goal
    istr = num2str(i);
    
    output_folder = [msg 'Cam' istr];
    output_img_folder = fullfile(opts.scene_img_folder, output_img_folder_name);
    
    % Create directory for the render images
    mkdir(output_img_folder, output_folder);
    
    output_folder = fullfile(output_img_folder_name, output_folder);
    
    % Active current camera
    if(num_goal > 1)
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 1'];
        maya_send{1}(cmd, 0);
    end
    
    render_heat_maps( population, init_heat_map.xyz, init_heat_map.size, ...
        opts.scene_name, opts.scene_img_folder, output_folder, maya_send);
    
    % Deactive current camera
    if(num_goal > 1)
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 0'];
        maya_send{1}(cmd, 0);
    end
end

end

