function [ error_v ] = render_attr_fitness( render_attr, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, maya_send, ...
    id, num_goal)
%RENDER_ATTR_FITNESS Render attr fitness function
persistent CACHE

if(isempty(CACHE))
    CACHE = containers.Map();
end

output_img_folder = [scene_img_folder output_img_folder_name];

num_error_foos = size(error_foo, 2);
error_v = zeros(num_error_foos, size(render_attr, 1));
num_variables = size(render_attr, 2);

best_error = realmax;
best_in_cache = false;
best_file_exists = false;
id_str = num2str(id);
best_save_path = [output_img_folder  'current' id_str '-Cam'];

for pop=1:size(render_attr, 1)
    key = num2str(render_attr(pop, :));
    if isKey(CACHE, key)
        error_v(:, pop) = CACHE(key);
    else
        %% Make temp dir for the render image
        tmpdirName = ['dir' num2str(pop) '-m' id_str];
        tmpdir = [output_img_folder tmpdirName];
        mkdir(output_img_folder, tmpdirName);
        
        %% Set the render attributes
        cmd = 'setFireAttributesNew(\"fire_volume_shader\"';
        for i=1:num_variables
            cmd = [cmd ', ' num2str(render_attr(pop, i))];
        end
        cmd = [cmd ')'];
        maya_send(cmd, 0);
        
        c_img = cell(num_goal, 1);
        
        for i=1:num_goal
            istr = num2str(i);
            
            %% Activate the current camera
            % Avoid activating/deactivating for single goal images, this is
            % a minor optimization, 0.02s for activating, 0.004s overhead
            % in multiple goal case
            if(num_goal > 1)
                cmd = ['setAttr \"camera' istr 'Shape.renderable\" 1'];
                maya_send(cmd, 0);
            end
            
            %% Set the folder and name of the render image
            cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
            cmd = [cmd scene_name '/' output_img_folder_name tmpdirName '/fireimage' ...
                istr '\"'];
            maya_send(cmd, 0);
            
            %% Render the image
            cmd = 'Mayatomr -verbosity 2 -render -renderVerbosity 2';
            maya_send(cmd, 1);
            
            %% Deactivate the current camera
            if(num_goal > 1)
                cmd = ['setAttr \"camera' istr 'Shape.renderable\" 0'];
                maya_send(cmd, 0);
            end
            
            %% Compute the error with respect to the goal image
            try
                img_path = [output_img_folder tmpdirName '/fireimage'];
                
                c_img{i} = imread([img_path istr '.tif']);
            catch ME
                msg = 'Could not read rendered image, try disabling any extra camera';
                causeException = MException('MATLAB:heat_map_fitness',msg);
                ME = addCause(ME,causeException);
                rethrow(ME);
            end
            
            c_img{i} = c_img{i}(:,:,1:3); % Transparency is not used, so ignore it
        end
        
        % Evaluate all the error functions, usually only one will be given
        for i=1:num_error_foos
            if(any(cellfun(@(x)sum(x(:)), c_img) == 0))
                % If any of the rendered image is completely black set the error manually
                error_v(i, pop) = 1;
            else
                error_v(i, pop) = sum(error_foo{i}(c_img));
            end
        end
        
        % Save the best images so far outside of the temp folder
        if(error_v(1, pop) < best_error)
            best_error = error_v(1, pop);
            
            for j=1:num_goal
                jstr = num2str(j);
                movefile([img_path jstr '.tif'], [best_save_path jstr '.tif']);
            end
            
            best_in_cache = false;
            best_file_exists = true;
        end
        
        % Delete the temporary files
        rmdir(tmpdir, 's')
        
        CACHE(key) = error_v(:,pop);
    end
end

if(best_in_cache && best_file_exists)
    delete([best_save_path '*.tif']);
end

end
