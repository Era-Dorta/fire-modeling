function [ error ] = heat_map_fitness( heat_map_v, xyz, whd, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
    port, mrLogPath, goal_img, goal_mask, img_mask, lb, ub)
%HEAT_MAP_FITNESS Heat map fitness function
%    Like heat_map_fitness function but it supports several goal images
%    given in a cell
%
%    See also HEAT_MAP_FITNESS

persistent CACHE

if(isempty(CACHE))
    CACHE = containers.Map();
end

output_img_folder = [scene_img_folder output_img_folder_name];

num_error_foos = size(error_foo, 2);
error = zeros(num_error_foos, size(heat_map_v, 1));

for pop=1:size(heat_map_v, 1)
    key = num2str(heat_map_v(pop, :));
    if isKey(CACHE, key)
        error(:, pop) = CACHE(key);
    else
        %% Make temp dir for the render image
        tmpdirName = ['dir' num2str(pop) '-' num2str(port)];
        tmpdir = [output_img_folder tmpdirName];
        system(['mkdir ' tmpdir ' < /dev/null']);
        
        %% Save the heat_map in a file
        heat_map_path = [scene_img_folder output_img_folder_name tmpdirName '/heat-map.raw'];
        volumetricData = struct('xyz', xyz, 'v', heat_map_v(pop, :)', 'size', whd, ...
            'count', size(xyz,1));
        save_raw_file(heat_map_path, volumetricData);
        
        %% Set the heat map file as temperature file
        % Either set the full path or set the file relative maya path for
        % temperature_file_first and force frame update to run
        cmd = 'setAttr -type \"string\" fire_volume_shader.temperature_file \"';
        cmd = [cmd '$HOME/' heat_map_path(3:end) '\"'];
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
        
        % The lower the value the smoother the volume is
        smooth_val = smoothnessEstimateGrad(xyz, heat_map_v(pop, :),  ...
            whd, lb, ub);
        
        % Up heat val
        upheat_val = upHeatEstimate(xyz, heat_map_v(pop, :), whd);
        
        % High values -> more heat up -> invert value
        upheat_val = 1.0 - upheat_val;
        
        % Relative weights for histogram, smoothness and upheat estimates.
        % If we want the fitness function to be [0,1] the weights must sum
        % up to one
        e_weights = [1/3, 1/3, 1/3];
        
        error(1, pop) = dot(e_weights, [error(1, pop), smooth_val, upheat_val]);
        
        % Delete the temporary files
        system(['rm -rf ' tmpdir ' < /dev/null &']);
        
        CACHE(key) = error(:,pop);
    end
end
end
