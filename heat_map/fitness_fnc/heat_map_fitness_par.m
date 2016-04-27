function [ error ] = heat_map_fitness_par( heat_map_v, xyz, whd, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
    ports, mrLogPath, num_goal, lb, ub)
%HEAT_MAP_FITNESS_PAR Heat map fitness parallel function
%   Heat map fitness function for optimization algorithms, the parallelism
%   works best if the Vectorized option of the optimizer is activated. It
%   supports one or several goal images.
%
%   See also HEAT_MAP_FITNESS

num_maya = size(ports, 2);

if(num_maya == 1 || size(heat_map_v, 1) <= num_maya)
    % When there are more Maya instances than data or if only one port was
    % given use a single instance to render al the data
    error = heat_map_fitness(heat_map_v, xyz, whd, error_foo, ...
        scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
        ports(1), mrLogPath, num_goal, lb, ub);
else
    num_hm = size(heat_map_v, 1);
    num_hm_per_thread = round(num_hm / num_maya);
    error_thread = cell(1, num_maya);
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
        
        % Asynchronous parallel call to the fitness function
        f(c_maya) = parfeval(@heat_map_fitness, 1,   ...
            heat_map_v(start_pop:end_pop, :), xyz, whd, error_foo,   ...
            scene_name, scene_img_folder, output_img_folder_name, ...
            sendMayaScript, ports(c_maya), mrLogPath, num_goal, lb, ub);
    end
    
    best_error = realmax;
    output_img_folder = [scene_img_folder output_img_folder_name];
    
    % Wait for the results
    for c_maya=1:num_maya
        error_thread{c_maya} = fetchOutputs(f(c_maya));
        c_error_b = min(error_thread{c_maya});
        if(c_error_b < best_error)
            best_error = c_error_b;
            best_save_path = [output_img_folder  'best-' num2str(ports(c_maya)) '.tif'];
        else
            % Keep only the best image
            file_path = [output_img_folder  'best-' num2str(ports(c_maya)) '.tif'];
            if(exist(file_path, 'file') == 2)
                delete(file_path);
            end
        end
    end
    
    first_path = [output_img_folder  'best-' num2str(ports(1)) '.tif'];
    
    % Make the best image have the first port
    if(~isequal(best_save_path, first_path) && ...
            exist(best_save_path, 'file') == 2)
        movefile(best_save_path, first_path);
    end
    
    % Concatenate all the errors in a vector
    error = cell2mat(error_thread);
end

end
