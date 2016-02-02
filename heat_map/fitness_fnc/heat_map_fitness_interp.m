function [ error ] = heat_map_fitness_interp( heat_map_v, xyz, whd, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
    port, mrLogPath, goal_img)
%HEAT_MAP_FITNESS_INTERP Heat map fitness function
%   Same as HEAT_MAP_FITNESS, but uses a interpolation to acelerate the
%   computation.
%
%   See also HEAT_MAP_FITNESS
persistent IS_INITIALIZED IMAGES_DB IMAGES_DB_HEATMAPS IMAGES_DB_DIR

% With smaller populations it should be bigger
dist_threshold = 500;
degree_tol = 5;

output_img_folder = [scene_img_folder output_img_folder_name];

if isempty(IS_INITIALIZED) || IS_INITIALIZED == false
    IS_INITIALIZED = true;
    % Make database folder
    IMAGES_DB_DIR = [output_img_folder 'image_db'];
    system(['mkdir ' IMAGES_DB_DIR]);
    IMAGES_DB = {};
end

num_error_foos = size(error_foo, 2);
error = zeros(num_error_foos, size(heat_map_v, 1));

for pop=1:size(heat_map_v, 1)
    interpolated = false;
    
    % Compute the distances to all the images
    c_distances = zeros(1, length(IMAGES_DB));
    for i=1:length(IMAGES_DB)
        c_distances(i) = norm(IMAGES_DB_HEATMAPS(:,i) - heat_map_v(pop, :)');
    end
    
    % disp(['min, max, mean dist is ' num2str([min(c_distances), max(c_distances), mean(c_distances)])]);
    
    % If there are enough images in the data base and the current heat map is
    % not too far away from the saved ones, then use interpolation
    [min_dist, min_ind] = min(c_distances);
    
    if(length(IMAGES_DB) >= 2 && min_dist < dist_threshold)
        % If the distance is small assume a 1 to 1 correspondence
        if(min_dist <= eps)
            error = IMAGES_DB{min_ind}.error;
            return;
        end
        
        % Find a linear combination of heat maps that is equal to the current
        % one and whose distance to the heat map is minimal
        
        % Assumes there is one and try to do it using the heat maps with minimal
        % distances
        %     lb = zeros(1, length(IMAGES_DB));
        %     ub = ones(1, length(IMAGES_DB));
        %     weights = linprog(c_distances, [], [], IMAGES_DB_HEATMAPS, heat_map_v, lb, ub);
        
        % Does not assume there is one and just tries to find the linear
        % combination that better matches the current heat map
        % Additional constrain that the weights must sum up to one
        %     Aeq = zeros(length(IMAGES_DB));
        %     Aeq(1,:) = 1;
        %     beq = zeros(1, length(IMAGES_DB));
        %     beq(1) = 1;
        %     weights = lsqlin(IMAGES_DB_HEATMAPS, heat_map_v', [], [], Aeq, beq, lb, ub);
        
        % TODO If the flag is -2, check if the weights and the reconstructed
        % heat map are within a tolerance, lets say sum(weights) in [0.9, 1.1]
        % and norm(reconstructed - heat_map_v) < 50, otherwise generate a new
        % point
        
        %     new_img = zeros(size(goal_img), DATA_TYPE);
        %
        %     % Do a simple linear interpolation to generate the new image
        %     for i=1:length(IMAGES_DB)
        %         % Compute for RGB
        %         new_img = new_img + IMAGES_DB{i}.image * weights(i);
        %     end
        
        % This would need some kind of sum after cellfun
        % new_img(:,:,1) = cellfun(@(img_db, i) img_db.image * c_distances(i), IMAGES_DB, indices);
        
        % Find a linear combination using only two images
        scale = [0, 0];
        freq = [0, 0];
        min_ind(2) = 1;
        
        % DB{min_ind} * scale(1), explains freq1 voxels in heat_map_v
        heat_map_rel = heat_map_v(pop, :)' ./ IMAGES_DB_HEATMAPS(:,min_ind(1));
        
        % Round the scale values for the mode computation to make sense
        heat_map_rel = round(heat_map_rel, 5);
        
        scale(1) = mode(heat_map_rel);
        
        % Round the heat map to get a better number for the frequency as we are
        % assuming that a change of +-1 degree won't affect much
        scaled_heat_map = abs(IMAGES_DB_HEATMAPS(:,min_ind(1)) * scale(1) - ...
            heat_map_v(pop, :)');
        freq(1) = sum(scaled_heat_map < degree_tol);
        
        nvars = length(heat_map_v(pop, :));
        
        % If there are values not cover by this heat min_ind heat map and
        % min_ind heat map explains at least 45% of the voxels
        if(freq(1) < nvars && freq(1) > 0.45 * nvars)
            % Get the indices of the unexplained voxels
            other_idx = find(scaled_heat_map >= degree_tol);
            
            % Compute the distances to all the images using the unexplained voxels
            c_distances = zeros(1, length(IMAGES_DB));
            for i=1:length(IMAGES_DB)
                if(i ~= min_ind(1))
                    c_distances(i) = norm(IMAGES_DB_HEATMAPS(other_idx,i) - heat_map_v(pop, other_idx)');
                else
                    % min_ind was already used, so assign a high distance
                    c_distances(i) = realmax;
                end
            end
            
            % Assume that min_ind2 heat map * scale(2), explains the rest of the
            % voxels in heat_map_v
            [~, min_ind(2)] = min(c_distances);
            heat_map_rel = heat_map_v(pop, other_idx)' ./ IMAGES_DB_HEATMAPS(other_idx, min_ind(2));
            
            heat_map_rel = round(heat_map_rel, 5);
            
            scale(2) = mode(heat_map_rel);
            
            freq(2) = sum(abs(IMAGES_DB_HEATMAPS(other_idx,min_ind(2)) * scale(2) - ...
                heat_map_v(pop, other_idx)') < degree_tol);
        end
        
        % If both heatmaps explain more that 90% of voxels of heat_map_v then
        % interpolate, otherwise go into slow rendering
        if( (freq(1) + freq(2)) >= 0.9 * nvars)
            % The interpolation rate is the scale by the percentage of voxels
            % explained by each heatmap
            weights(1) = scale(1) * (freq(1) / nvars);
            weights(2) = scale(2) * (1 - freq(1) / nvars);
            
            % Create the new image with a linear combination
            new_img = IMAGES_DB{min_ind(1)}.image * weights(1) + ...
                IMAGES_DB{min_ind(2)}.image * weights(2);
            
            % Evaluate all the error functions, usually only one will be given
            for i=1:num_error_foos
                if(sum(new_img(:)) == 0)
                    % If the rendered image is completely black set the error manually
                    error(i, pop) = realmax;
                else
                    error(i, pop) = sum(feval(error_foo{i}, goal_img, new_img));
                end
            end
            interpolated = true;
        end
    end
    
    if(~interpolated)
        % Render and add image to data base
        %% Save the heat_map in a file
        heat_map_path = [IMAGES_DB_DIR '/heat-map' num2str(length(IMAGES_DB)) '.raw'];
        volumetricData = struct('xyz', xyz, 'v', heat_map_v(pop,:)', 'size', whd, ...
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
        img_name = ['/fireimage' num2str(length(IMAGES_DB))];
        cmd = [cmd [scene_name IMAGES_DB_DIR(length(scene_img_folder):end)] img_name '\"'];
        sendToMaya(sendMayaScript, port, cmd);
        
        %% Render the image
        % This command only works on Maya running in batch mode, if running with
        % the GUI, use Mayatomr -preview. and then save the image with
        % $filename = "Path to save";
        % renderWindowSaveImageCallback "renderView" $filename "image";
        startTime = tic;
        cmd = 'Mayatomr -render -renderVerbosity 2';
        sendToMaya(sendMayaScript, port, cmd, 1, mrLogPath);
        %fprintf('Image rendered with');
        
        %% Compute the error with respect to the goal image
        img_path = [IMAGES_DB_DIR img_name '.tif'];
        c_img = imread(img_path);
        c_img = c_img(:,:,1:3); % Transparency is not used, so ignore it
        
        % Evaluate all the error functions, usually only one will be given
        for i=1:num_error_foos
            if(sum(c_img(:)) == 0)
                % If the rendered image is completely black set the error manually
                error(i, pop) = realmax;
            else
                error(i, pop) = sum(feval(error_foo{i}, goal_img, c_img));
            end
        end
        
        % Print the rest of the information on the same line
        %fprintf(' error %.2f, in %.2f seconds.\n', error(1), toc(startTime));
        
        % Delete the heatmap file
        system(['rm ' heat_map_path '&']);
        
        %% Add the new image to the database
        IMAGES_DB{end + 1} = struct('image', c_img, 'error', error, 'filename', ...
            img_path);
        IMAGES_DB_HEATMAPS(:, end + 1) = heat_map_v(pop,:)';
    end
end
end
