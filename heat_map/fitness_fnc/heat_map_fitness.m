function [ error ] = heat_map_fitness( heat_map_v, xyz, whd, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
    port, mrLogPath, goal_img, goal_mask, img_mask)
%HEAT_MAP_FITNESSN Heat map fitness function
%   ERROR = HEAT_MAP_FITNESS( HEAT_MAP_V, XYZ, WHD, ERROR_FOO, ...
%   SCENE_NAME, SCENE_IMG_FOLDER, OUTPUT_IMG_FOLDER_NAME, SENDMAYASCRIPT, ...
%   PORT, MRLOGPATH, GOAL_IMG) Fitness function for optimization
%   algorithms

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
        
        %% Set the folder and name of the render image
        cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
        cmd = [cmd scene_name '/' output_img_folder_name tmpdirName '/fireimage' '\"'];
        sendToMaya(sendMayaScript, port, cmd);
        
        %% Render the image
        % This command only works on Maya running in batch mode, if running with
        % the GUI, use Mayatomr -preview. and then save the image with
        % $filename = "Path to save";
        % renderWindowSaveImageCallback "renderView" $filename "image";
        startTime = tic;
        cmd = 'Mayatomr -verbosity 2 -render -renderVerbosity 2';
        sendToMaya(sendMayaScript, port, cmd, 1, mrLogPath);
        %fprintf('Image rendered with');
        
        %% Compute the error with respect to the goal image
        try
            c_img = imread([output_img_folder tmpdirName '/fireimage.tif']);
        catch ME
            msg = ['Could not read rendered image, make sure only one camera' ...
                ' is renderable in the Maya scene'];
            causeException = MException('MATLAB:heat_map_fitness',msg);
            ME = addCause(ME,causeException);
            rethrow(ME);
        end
        c_img = c_img(:,:,1:3); % Transparency is not used, so ignore it
        
        % Evaluate all the error functions, usually only one will be given
        for i=1:num_error_foos
            if(sum(c_img(:)) == 0)
                % If the rendered image is completely black set the error manually
                error(i, pop) = realmax;
            else
                error(i, pop) = sum(feval(error_foo{i}, goal_img, c_img, ...
                    goal_mask, img_mask));
            end
        end
        
        % Print the rest of the information on the same line
        %fprintf(' error %.2f, in %.2f seconds.\n', error(1), toc(startTime));
        
        % Delete the temporary files
        system(['rm -rf ' tmpdir ' < /dev/null &']);
        
        CACHE(key) = error(:,pop);
    end
end
end
