function [ error ] = render_attr_fitness_par(  render_attr, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, maya_send, ...
    num_goal)
%RENDER_ATTR_FITNESS_PAR Heat map fitness parallel function
%   Render attributes fitness function for optimization algorithms, the parallelism
%   works best if the Vectorized option of the optimizer is activated. It
%   supports one or several goal images.
%
%   See also RENDER_ATTR_FITNESS

num_maya = numel(maya_send);

if(num_maya == 1 || size(render_attr, 1) <= num_maya)
    % When there are more Maya instances than data, use a single instance
    % to render al the data
    error = feval(@render_attr_fitness, render_attr, error_foo, scene_name, ...
        scene_img_folder, output_img_folder_name, maya_send{1}, 1, num_goal);
else
    num_ra = size(render_attr, 1);
    num_ra_per_thread = floor(num_ra / num_maya);
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
            scene_img_folder, output_img_folder_name, maya_send{c_maya}, ...
            c_maya, num_goal);
    end
    
    min_error = realmax;
    best_error_idx = 1;
    
    % Wait for the results
    for c_maya=1:num_maya
        error_thread{c_maya} = fetchOutputs(f(c_maya));
        
        min_thread_error = min(error_thread{c_maya});
        if min_thread_error < min_error
            best_error_idx = c_maya;
            min_error = min_thread_error;
        end
    end
    
    % Delete the suboptimal images
    output_img_folder = [scene_img_folder output_img_folder_name];
    img_name = 'current';
    
    for c_maya=1:num_maya
        if c_maya ~= best_error_idx
            file_path = [output_img_folder img_name num2str(c_maya) '-Cam*.tif'];
            if ~isempty(dir(file_path))
                delete(file_path);
            end
        end
    end
    
    first_path = [output_img_folder  img_name '1-Cam'];
    best_save_path = [output_img_folder  img_name num2str(best_error_idx) '-Cam'];
    
    % Make the best image have the first id, assume that if the first
    % camera file exists, the others do as well
    if(best_error_idx ~= 1 && exist([best_save_path '1.tif'], 'file') == 2)
        for j=1:num_goal
            jstr = num2str(j);
            movefile([best_save_path jstr '.tif'], [first_path jstr '.tif']);
        end
    end
    
    % Concatenate all the errors in a vector
    error = cell2mat(error_thread);
end

end
