function [ error_v ] = camera_align_fitness( cam_attr, ~, ~, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, maya_send, ...
    id, num_goal, prior_fncs, prior_weights, color_space, use_cache, ...
    ~)
%CAMERA_ALIGN_FITNESS Camera fitness function
%    Like heat_map_fitness function but it supports several goal images
%    given in a cell
%

persistent CACHE

if use_cache
    if(isempty(CACHE))
        CACHE = containers.Map();
    end
end

output_img_folder = [scene_img_folder output_img_folder_name];

num_error_foos = size(error_foo, 2);
error_v = zeros(1, size(cam_attr, 1));
error_vals = zeros(num_error_foos, 1);
num_variables = size(cam_attr, 2)/num_goal;

num_prior_fncs = numel(prior_fncs);
prior_vals = zeros(num_prior_fncs, 1);

best_error = realmax;
best_in_cache = false;
best_file_exists = false;
id_str = num2str(id);
best_save_path = [output_img_folder  'current' id_str '-Cam'];

for pop=1:size(cam_attr, 1)
    if use_cache
        key = num2str(cam_attr(pop, :));
    end
    if use_cache && isKey(CACHE, key)
        error_v(:, pop) = CACHE(key);
        
        if(error_v(pop) < best_error)
            best_error = error_v(pop);
            best_in_cache = true;
        end
    else
        %% Make temp dir for the render image
        tmpdirName = ['dir' num2str(pop) '-m' id_str];
        tmpdir = [output_img_folder tmpdirName];
        mkdir(output_img_folder, tmpdirName);
        
         %% Set the render attributes
         for i=1:num_goal
            cmd = ['setCameraAttributesNew(\"camera' num2str(i) '\"'];
            for j=1:num_variables
                cmd = [cmd ', ' num2str(cam_attr(pop, j + (i-1)*num_variables))];
            end
            cmd = [cmd ')'];
            maya_send(cmd, 0);
         end

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
            send_render_cmd(maya_send, istr);
            
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
        
        % Transform the image to a new color space
        c_img_converted = colorspace_transform_imgs(c_img, 'RGB', color_space);
        
        % Evaluate all the error functions, usually only one will be given
        error_vals(:) = 0;
        for i=1:num_error_foos
            error_vals(i,:) = sum(error_foo{i}(c_img_converted));
        end
        
        prior_vals(:) = 0;
        for i=1:num_prior_fncs
            prior_vals(i,:) = prior_fncs{i}(cam_attr(pop, :));
        end
        
        error_v(1, pop) = prior_weights * [error_vals; prior_vals];
        
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
        
        if use_cache
            CACHE(key) = error_v(:,pop);
        end
    end
end

if(use_cache && best_in_cache && best_file_exists)
    delete([best_save_path '*.tif']);
end

end
