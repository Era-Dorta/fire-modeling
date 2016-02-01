function [ error ] = heat_map_fitness_par( heat_map_v, xyz, whd, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
    port, mrLogPath, goal_img)
%HEAT_MAP_FITNESS_PAR Heat map fitness parallel function

num_maya = size(port, 2);

if(size(heat_map_v, 1) <= num_maya)
    error = heat_map_fitness( heat_map_v, xyz, whd, error_foo, ...
        scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
        port(1), mrLogPath, goal_img);
else
    num_hm = size(heat_map_v, 1);
    num_hm_thread = round(num_hm / num_maya);
    
    error_thread = cell(1, num_maya);
    hm_thread = cell(1, num_maya);
    
    % Do a preevaluation of the error function to initialize its persistent
    % variables
    feval(error_foo{1}, goal_img, goal_img);
    
    % Divide the data in chunks for each thread as matlab complains about
    % too much data sharing between the processes
    for c_maya=1:num_maya
        start_pop = 1 + num_hm_thread * (c_maya - 1);
        end_pop = start_pop + num_hm_thread - 1;
        
        if(c_maya == num_maya)
            % Fix the last index for the last thread, so the last thread
            % may have more or less work than the rest
            end_pop = num_hm;
        end
        
        hm_thread{c_maya} = heat_map_v(start_pop:end_pop, :);
    end
    
    % Launch each evaluation in parallel
    parfor c_maya=1:num_maya
        error_thread{c_maya} = heat_map_fitness( hm_thread{c_maya}, xyz, whd,  ...
            error_foo, scene_name, scene_img_folder, output_img_folder_name,  ...
            sendMayaScript, port(c_maya), mrLogPath, goal_img);
    end
    
    % Concatenate all the errors in a vector
    error = cell2mat(error_thread);
end

end
