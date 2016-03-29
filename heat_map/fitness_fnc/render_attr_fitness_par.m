function [ error ] = render_attr_fitness_par(  render_attr, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
    ports, mrLogPath, goal_img, goal_mask, img_mask)
%RENDER_ATTR_FITNESS_PAR Heat map fitness parallel function
%   Render attributes fitness function for optimization algorithms, the parallelism
%   works best if the Vectorized option of the optimizer is activated. It
%   supports one or several goal images.
%
%   See also RENDER_ATTR_FITNESS

num_maya = size(ports, 2);

if(num_maya == 1 || size(render_attr, 1) <= num_maya)
    % When there are more Maya instances than data, use a single instance
    % to render al the data
    error = feval(@render_attr_fitness, render_attr, error_foo, scene_name, ...
        scene_img_folder, output_img_folder_name, sendMayaScript, ...
        ports(1), mrLogPath, goal_img, goal_mask, img_mask);
else
    num_ra = size(render_attr, 1);
    num_ra_per_thread = round(num_ra / num_maya);
    error_thread = cell(1, num_maya);
    f = parallel.FevalFuture;
    
    % Launch each evaluation in parallel
    for c_maya=1:num_maya
        % Compute the render attribute indices that the current maya
        % instance is going to render
        start_pop = 1 + num_ra_per_thread * (c_maya - 1);
        end_pop = start_pop + num_ra_per_thread - 1;
        
        if(c_maya == num_maya)
            % Fix the last index for the last thread, so the last thread
            % may have more or less work than the rest
            end_pop = num_ra;
        end
        
        % Asynchronous parallel call to the fitness function
        f(c_maya) = parfeval(@render_attr_fitness, 1,   ...
            render_attr(start_pop:end_pop, :), error_foo, scene_name, ...
            scene_img_folder, output_img_folder_name, sendMayaScript, ...
            ports(c_maya), mrLogPath, goal_img, goal_mask, img_mask);
    end
    
    % Wait for the results
    for c_maya=1:num_maya
        error_thread{c_maya} = fetchOutputs(f(c_maya));
    end
    
    % Concatenate all the errors in a vector
    error = cell2mat(error_thread);
end

end
