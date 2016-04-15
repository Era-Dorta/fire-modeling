function [ error ] = render_attr_fitness( render_attr, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
    port, mrLogPath, goal_img, goal_mask, img_mask)
%RENDER_ATTR_FITNESS Render attr fitness function
persistent CACHE

if(isempty(CACHE))
    CACHE = containers.Map();
end

output_img_folder = [scene_img_folder output_img_folder_name];

num_error_foos = size(error_foo, 2);
error = zeros(num_error_foos, size(render_attr, 1));
num_variables = size(render_attr, 2);

for pop=1:size(render_attr, 1)
    key = num2str(render_attr(pop, :));
    if isKey(CACHE, key)
        error(:, pop) = CACHE(key);
    else
        %% Make temp dir for the render image
        tmpdirName = ['dir' num2str(pop) '-' num2str(port)];
        tmpdir = [output_img_folder tmpdirName];
        mkdir(output_img_folder, tmpdirName);
        
        %% Set the render attributes
        cmd = 'setFireAttributesNew(\"fire_volume_shader\"';
        for i=1:num_variables
            cmd = [cmd ', ' num2str(render_attr(pop, i))];
        end
        cmd = [cmd ')'];
        sendToMaya(sendMayaScript, port, cmd);
        
        num_goal = numel(goal_img);
        c_img = cell(num_goal, 1);
        
        for i=1:num_goal
            istr = num2str(i);
            
            %% Activate the current camera
            % Avoid activating/deactivating for single goal images, this is
            % a minor optimization, 0.02s for activating, 0.004s overhead
            % in multiple goal case
            if(num_goal > 1)
                cmd = ['setAttr \"camera' istr 'Shape.renderable\" 1'];
                sendToMaya(sendMayaScript, port, cmd);
            end
            
            %% Set the folder and name of the render image
            cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
            cmd = [cmd scene_name '/' output_img_folder_name tmpdirName '/fireimage' ...
                istr '\"'];
            sendToMaya(sendMayaScript, port, cmd);
            
            %% Render the image
            cmd = 'Mayatomr -verbosity 2 -render -renderVerbosity 2';
            sendToMaya(sendMayaScript, port, cmd, 1, mrLogPath);
            %fprintf('Image rendered with');
            
            %% Deactivate the current camera
            if(num_goal > 1)
                cmd = ['setAttr \"camera' istr 'Shape.renderable\" 0'];
                sendToMaya(sendMayaScript, port, cmd);
            end
            
            %% Compute the error with respect to the goal image
            try
                c_img{i} = imread([output_img_folder tmpdirName '/fireimage' istr '.tif']);
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
                error(i, pop) = realmax;
            else
                error(i, pop) = sum(feval(error_foo{i}, goal_img, c_img, ...
                    goal_mask, img_mask));
            end
        end
        
        % Print the rest of the information on the same line
        %fprintf(' error %.2f, in %.2f seconds.\n', error(1), toc(startTime));
        
        % Delete the temporary files
        rmdir(tmpdir, 's')
        
        CACHE(key) = error(:,pop);
    end
end
end
