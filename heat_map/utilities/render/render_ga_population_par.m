function render_ga_population_par( population, opts, maya_send, num_goal, ...
    init_heat_map, output_img_folder_name, msg, do_collage)
%RENDER_GA_POPULATION Renders GA inital and final population
%   RENDER_GA_POPULATION( POPULATION, OPTS, MAYA_SEND, NUM_GOAL, ...
%    INIT_HEAT_MAP, OUTPUT_IMG_FOLDER_NAME, MSG )

disp(['Rendering the ' msg ' in ' opts.scene_img_folder ...
    output_img_folder_name msg 'Cam<d>' ]);

num_maya = numel(maya_send);

num_hm = size(population, 1);

if(num_maya == 1 || num_hm <= num_maya)
    % Not enough Population to run in parallel
    render_ga_population(population, opts, maya_send{1}, num_goal, ...
        init_heat_map, output_img_folder_name, msg, 0);
else
    
    num_hm_per_thread = round(num_hm / num_maya);
    f = parallel.FevalFuture;
    
    % Launch each evaluation in parallel
    for c_maya=1:num_maya
        % Compute the heatmap indices that the current maya instance is
        % going to render
        start_pop = 1 + num_hm_per_thread * (c_maya - 1);
        end_pop = start_pop + num_hm_per_thread - 1;
        
        if(c_maya == num_maya)
            % Fix the last index for the last thread, so the last thread
            % may have more or less work than the rest
            end_pop = num_hm;
        end
        
        % Asynchronous parallel call to the render function
        f(c_maya) = parfeval(@render_ga_population, 0, ...
            population(start_pop:end_pop, :), opts, maya_send{c_maya}, num_goal, ...
            init_heat_map, output_img_folder_name, msg, start_pop - 1);
    end
    
    % Wait for the results
    render_flag = wait(f);
    
    if ~render_flag
        error('Error occured when rendering, check logs');
    end
end

% Do a collage with all the images
if do_collage
    for i=1:num_goal
        istr = num2str(i);
        
        output_folder = fullfile(opts.scene_img_folder, output_img_folder_name, ...
            [msg 'Cam' istr]);
        
        image_collage(num_hm, output_folder);
    end
end

end

