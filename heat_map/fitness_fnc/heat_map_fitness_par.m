function [ error ] = heat_map_fitness_par( heat_map_v, xyz, whd, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
    ports, mrLogPath, goal_img)
%HEAT_MAP_FITNESS_PAR Heat map fitness parallel function
%   Heat map fitness function for optimization algorithms, the parallelism
%   works best if the Vectorized option of the optimizer is activated. It
%   supports one or several goal images.
%
%   See also HEAT_MAP_FITNESS and HEAT_MAP_FITNESSN

num_maya = size(ports, 2);

% If the goal image is a cell of images use the fitness function
% which supports several goal images
if(~iscell(goal_img))
    fitnesss_internal = @heat_map_fitness;
else
    fitnesss_internal = @heat_map_fitnessN;
end

if(size(heat_map_v, 1) <= num_maya)
    % When there are more Maya instances than data, use a single instance
    % to render al the data
    error = feval(fitnesss_internal, heat_map_v, xyz, whd, error_foo, ...
        scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
        ports(1), mrLogPath, goal_img);
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
        f(c_maya) = parfeval(fitnesss_internal, 1,   ...
            heat_map_v(start_pop:end_pop, :), xyz, whd, error_foo,   ...
            scene_name, scene_img_folder, output_img_folder_name, ...
            sendMayaScript, ports(c_maya), mrLogPath, goal_img);
    end
    
    % Wait for the results
    for c_maya=1:num_maya
        error_thread{c_maya} = fetchOutputs(f(c_maya));
    end
    
    % Concatenate all the errors in a vector
    error = cell2mat(error_thread);
end

end
