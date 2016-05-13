function heatMapReconstruction(args_path, ports, logfile)
%HEATMAPRECONSTRUCTION Performs a heat map reconstruction from a goal image
%   HEATMAPRECONSTRUCTION(ARGS_PATH, PORTS, LOGFILE)
%   ARGS_PATH is the path of a .mat file with arguments for the
%   optimization
%   PORTS is a vector containing port numbers that Maya is listening to
%   LOGFILE is only required when running in batch mode, is a string with
%   the path of the current log file

%% Parameter initalization
% N.B. If Matlab is started from the GUI and custom paths are used for the
% Maya plugins, Matlab will not read the Maya path variables that were
% defined in the .bashrc file and the render script will fail, a
% workouround is to redefine them here:
% setenv('MAYA_SCRIPT_PATH', 'scripts path');
% setenv('MI_CUSTOM_SHADER_PATH', ' shaders include path');
% setenv('MI_LIBRARY_PATH', 'shaders path');

% Add the subfolders of heat map to the Matlab path
addpath(genpath(fileparts(mfilename('fullpath'))));

opts = load(args_path);

rng(opts.rand_seed);

%% Setting clean up functions
% Clear all the functions
clearCloseObj = onCleanup(@clear_cache);
if(numel(ports) > 1)
    % If running of parallel, clear the functions in the workers as well
    clearParCloseObj = onCleanup(@() parfevalOnAll(gcp, @clear_cache, 0));
end

%% Avoid data overwrites by always creating a new folder
try
    if(nargin < 2)
        error('Not enough input arguments.');
    end
    
    if(isBatchMode() && nargin < 3)
        error('Logfile name is required when running in batch mode');
    end
    
    % Find the last folder
    dir_num = 0;
    while(exist([opts.scene_img_folder 'hm_search_' num2str(dir_num)], 'dir') == 7)
        dir_num = dir_num + 1;
    end
    
    % Create a new folder to store the data
    output_img_folder = [opts.scene_img_folder 'hm_search_' num2str(dir_num) '/'];
    output_img_folder_name = ['hm_search_' num2str(dir_num) '/'];
    summary_file = [output_img_folder 'summary_file'];
    % It will be saved as fig and tiff
    error_figure = [output_img_folder 'error_function'];
    paths_str = struct('summary',  summary_file, 'errorfig', error_figure, ...
        'output_folder',  output_img_folder, 'ite_img', [output_img_folder  ...
        'current1-Cam'], 'visualization_fig_path', [output_img_folder ...
        'solver-visualization-2D']);
    maya_log = [opts.scene_img_folder output_img_folder_name 'maya.log'];
    
    %% Read goal and mask image/s
    num_goal = numel(opts.goal_img_path);
    
    % For MSE resize the goal image to match the synthetic image
    if(isequal(opts.error_foo{1}, @MSE))
        resize_goal = true;
    else
        resize_goal = false;
    end
    [ goal_img, goal_mask, img_mask ] = readGoalAndMask( opts.goal_img_path, ...
        opts.mask_img_path, opts.goal_mask_img_path, resize_goal);
    
    %% SendMaya script initialization
    % Render script is located in the same maya_comm folder
    [currentFolder,~,~] = fileparts(mfilename('fullpath'));
    sendMayaScript = [currentFolder '/maya_comm/sendMaya.rb'];
    
    % Each maya instance usually renders using 4 cores
    numMayas = numel(ports);
    maya_send = cell(numMayas, 1);
    
    for i=1:numMayas
        maya_send{i} = @(cmd, isRender) sendToMaya( sendMayaScript, ...
            ports(i), cmd, maya_log, isRender);
    end
    
    %% Volumetric data initialization
    init_heat_map = read_raw_file([opts.project_path opts.raw_file_path]);
    
    %% Maya initialization
    
    for i=1:numMayas
        disp(['Loading scene in Maya:' num2str(ports(i))]);
        % Set project to fire project directory
        cmd = 'setProject \""$HOME"/maya/projects/fire\"';
        maya_send{i}(cmd, 0);
        
        % Open our test scene
        cmd = ['file -open -force \"scenes/' opts.scene_name '.ma\"'];
        maya_send{i}(cmd, 0);
        
        % Force a frame update, as batch rendering later does not do it, this
        % will fix any file name errors due to using the same scene on
        % different computers
        cmd = '\$ctime = \`currentTime -query\`; currentTime 1; currentTime \$ctime';
        maya_send{i}(cmd, 0);
        
        % Set the fuel type
        cmd = ['setAttr \"fire_volume_shader.fuel_type\" ' num2str(opts.fuel_type)];
        maya_send{i}(cmd, 0);
        
        % Deactive all but the first camera if there is more than one goal
        % image
        for j=2:num_goal
            cmd = ['setAttr \"camera' num2str(j) 'Shape.renderable\" 0'];
            maya_send{i}(cmd, 0);
        end
    end
    
    %% Ouput folder
    disp(['Creating new output folder ' output_img_folder]);
    mkdir(opts.scene_img_folder, output_img_folder_name);
    
    %% Summary data is mainly the options from the load file
    summary_data = opts;
    
    %% Input data preprocessing
    mkdir(output_img_folder, 'preprocessed_input_images');
    preprocessed_path = fullfile(output_img_folder, 'preprocessed_input_images');
    
    [goal_img, goal_mask, img_mask, bin_mask_threshold] = preprocess_images(...
        goal_img, goal_mask, img_mask, opts.bin_mask_threshold, true, ...
        fullfile(preprocessed_path, 'grouped-images-Cam'));
    
    % Save the preprocessed images in the preprocessed_path folder using
    % normalized names and extensions
    norm_names = get_norm_names( 'Goal-Cam', '.tif', num_goal);
    summary_data.p_goal_img_path = save_cell_images( goal_img, ...
        norm_names, preprocessed_path);
    
    norm_names = get_norm_names( 'Goal-Mask-Cam', '.tif', num_goal);
    summary_data.p_goal_mask_img_path = save_cell_images( goal_mask, ...
        norm_names, preprocessed_path);
    
    norm_names = get_norm_names( 'Synthetic-Mask-Cam', '.tif', num_goal);
    summary_data.p_mask_img_path = save_cell_images( img_mask, ...
        norm_names, preprocessed_path);
    
    %% Summary extra data
    summary_data.NumMaya = numMayas;
    summary_data.bin_mask_threshold = bin_mask_threshold';
    summary_data.Ports = ports;
    summary_data.IsBatchMode = isBatchMode();
    summary_data.FuelName = get_fuel_name(opts.fuel_type);
    
    %% Fitness function definition
    
    % Encapsulate the distance function in the error function
    error_foo{1} = @(x) opts.error_foo{1}(goal_img, x, goal_mask, img_mask, ...
        opts.dist_foo);
    
    [ prior_fncs, prior_weights ] = get_prior_fncs_from_file( ...
        opts, init_heat_map, goal_img, goal_mask, opts.LB, ...
        opts.UB, opts.fuel_type, 'fitness', true);
    
    % Wrap the fitness function into an anonymous function whose only
    % parameter is the heat map
    if(opts.use_approx_fitness)
        
        approx_error_foo = @(x) opts.approx_error_foo(x, goal_img, goal_mask, ...
            opts.dist_foo, opts.fuel_type);
        
        fitness_foo = @(x)heat_map_fitness_approx(x, approx_error_foo, ...
            prior_fncs, prior_weights);
    else
        fitness_foo = @(x)heat_map_fitness_par(x, init_heat_map.xyz,  ...
            init_heat_map.size, error_foo, opts.scene_name, opts.scene_img_folder,  ...
            output_img_folder_name, maya_send, num_goal, prior_fncs, ...
            prior_weights);
    end
    
    %% Solver call
    disp('Launching optimization algorithm');
    switch opts.solver
        case 'ga'
            [heat_map_v, ~, ~] = do_genetic_solve( opts.LB, opts.UB, init_heat_map, ...
                fitness_foo, paths_str, summary_data, goal_img, goal_mask, ...
                opts.fuel_type, opts.solver_args_path);
        case 'sa'
            [heat_map_v, ~, ~] = do_simulanneal_solve( opts.LB, opts.UB, ...
                init_heat_map, fitness_foo, paths_str, summary_data, ...
                opts.solver_args_path);
        case 'ga-re'
            % For the solve with reconstruction the size changes so leave
            % those two parameters open, so the function can modify them.
            % The same applies to the prior functions.
            prior_fncs = get_prior_fncs_from_file( opts, ...
                init_heat_map, goal_img, goal_mask, opts.LB, opts.UB, ...
                opts.fuel_type, 'fitness', false);
            
            if(opts.use_approx_fitness)
                fitness_foo = @(v, prior_fncs) ...
                    heat_map_fitness_approx(v, approx_error_foo, ...
                    prior_fncs, prior_weights);
            else
                fitness_foo = @(v, xyz, whd, prior_fncs) ...
                    heat_map_fitness_par(v, xyz, whd, error_foo, ...
                    opts.scene_name, opts.scene_img_folder, output_img_folder_name, ...
                    maya_send, num_goal, prior_fncs, prior_weights);
            end
            
            % Extra paths needed in the solver
            paths_str.imprefixpath = [opts.scene_name '/' output_img_folder_name];
            
            [heat_map_v, ~, ~] = do_genetic_solve_resample(opts.LB, opts.UB, ...
                init_heat_map, fitness_foo, paths_str, maya_send, num_goal, ...
                summary_data, goal_img, goal_mask, opts.fuel_type, ...
                opts.solver_args_path, prior_fncs);
        case 'grad'
            [heat_map_v, ~, ~] = do_gradient_solve( opts.LB, opts.UB, init_heat_map, ...
                fitness_foo, paths_str, summary_data, opts.solver_args_path);
        case 'cmaes'
            % CMAES gets the data in column order so transpose it for it
            % to work
            if(opts.use_approx_fitness)
                fitness_foo = @(x)heat_map_fitness_approx(x',  ...
                    approx_error_foo, prior_fncs, prior_weights);
            else
                fitness_foo = @(x)heat_map_fitness_par(x', init_heat_map.xyz,  ...
                    init_heat_map.size, error_foo, opts.scene_name, opts.scene_img_folder,  ...
                    output_img_folder_name, maya_send, num_goal, prior_fncs, ...
                    prior_weights);
            end
            
            heat_map_v = do_cmaes_solve( opts.LB, opts.UB, init_heat_map, fitness_foo, ...
                paths_str, summary_data, numMayas > 1, opts.solver_args_path);
        case 'lhs'
            heat_map_v = do_lhs_solve( opts.LB, opts.UB, init_heat_map, fitness_foo, ...
                paths_str, summary_data, opts.solver_args_path);
        otherwise
            solver_names = ['[''ga'', ''sa'', ''ga-re'', ''grad'', ' ...
                '''cmaes'', ''lhs'']'];
            error(['Invalid solver, choose one of ' solver_names ]);
    end
    
    % Solvers output a row vector, but we are working with column vectors
    heat_map_v = heat_map_v';
    
    %% Save the best heat map in a raw file
    heat_map_path = [output_img_folder 'heat-map.raw'];
    disp(['Final heat map saved in ' heat_map_path]);
    heat_map = struct('xyz', init_heat_map.xyz, 'v', heat_map_v, 'size', ...
        init_heat_map.size, 'count', init_heat_map.count);
    save_raw_file(heat_map_path, heat_map);
    
    %%  Render the best image again
    % Set the heat map file as temperature file
    % Either set the full path or set the file relative maya path for
    % temperature_file_first and force frame update to run
    cmd = 'setAttr -type \"string\" fire_volume_shader.temperature_file \"';
    cmd = [cmd '$HOME/' output_img_folder(3:end) 'heat-map.raw\"'];
    maya_send{1}(cmd, 0);
    
    disp(['Rendering final images in ' output_img_folder 'optimized-Cam<d>.tif' ]);
    
    for i=1:num_goal
        istr = num2str(i);
        
        % Active current camera
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 1'];
        maya_send{1}(cmd, 0);
        
        % Set the folder and name of the render image
        cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
        cmd = [cmd opts.scene_name '/' output_img_folder_name 'optimized-Cam' ...
            istr '\"'];
        maya_send{1}(cmd, 0);
        
        % Render the image
        tic;
        cmd = 'Mayatomr -verbosity 2 -render -renderVerbosity 2';
        maya_send{1}(cmd, 1);
        
        % Deactivate the current camera
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 0'];
        maya_send{1}(cmd, 0);
    end
    
    %% Append the real error if using the approx fitness
    if(opts.use_approx_fitness)
        L = load([paths_str.summary '.mat']);
        
        c_img = cell(num_goal, 1);
        for i=1:num_goal
            c_img{i} = imread([output_img_folder 'optimized-Cam' num2str(i) '.tif']);
            c_img{i} = c_img{i}(:,:,1:3); % Transparency is not used, so ignore it
        end
        
        clear_cache; % Clear the fnc cache as we are evaluating again
        
        L.summary_data.RealError = sum(error_foo{1}(c_img));
        
        disp(['Real error ' num2str(L.summary_data.RealError)]);
        summary_data = L.summary_data;
        save([paths_str.summary '.mat'], 'summary_data', '-append');
        
        append_to_summary_file(paths_str.summary, ['Real error is '...
            num2str(L.summary_data.RealError)]);
    end
    
    %% Add single view fitness value for multigoal optimization
    if(num_goal > 1)
        L = load([paths_str.summary '.mat']);
        
        c_img = imread([output_img_folder 'optimized-Cam1.tif']);
        c_img = c_img(:,:,1:3); % Transparency is not used, so ignore it
        
        clear_cache; % Clear the fnc cache as we are evaluating again
        
        L.summary_data.ImageErrorSingleView = sum(error_foo{1}({c_img}));
        
        summary_data = L.summary_data;
        save([paths_str.summary '.mat'], 'summary_data', '-append');
        
        append_to_summary_file(paths_str.summary, ['ImageErrorSingleView is '...
            num2str(L.summary_data.ImageErrorSingleView)]);
    end
    
    %% Render the initial and final population in a folder
    % With the ga-re solver there are several initial population files so
    % avoid the rendering in that case
    if ~any(strcmp(opts.solver, {'ga-re', 'lhs'})) && ~opts.use_approx_fitness
        L = load([paths_str.output_folder 'OutputData.mat']);
        
        if( strcmp(opts.solver,'cmaes'))
            % Transpose to get row order as the cmaes population is in
            % column order
            L.InitialPopulation = L.InitialPopulation';
            L.FinalPopulation = L.FinalPopulation';
        end
        
        render_ga_population( L.InitialPopulation, opts, maya_send, num_goal, ...
            init_heat_map, output_img_folder_name, 'InitialPopulation' );
        
        render_ga_population( L.FinalPopulation, opts, maya_send, num_goal, ...
            init_heat_map, output_img_folder_name, 'FinalPopulation' );
    end
    
    %% Move the best per iteration images to a folder
    best_img_iter_path = [output_img_folder 'best-iter*'];
    if ~isempty(dir(best_img_iter_path)) % Check if any image was generated
        for i=1:num_goal
            istr = num2str(i);
            best_img_iter_folder = [output_img_folder 'best-iter-Cam' istr];
            
            mkdir(best_img_iter_folder);
            movefile([best_img_iter_path '-Cam' istr '.tif'], best_img_iter_folder);
        end
    end
    
    %% Resource clean up after execution
    
    % If running in batch mode, exit matlab
    if(isBatchMode())
        move_file( logfile, [output_img_folder 'matlab.log'] );
        exit;
    else
        % If GUI running, show the computed heat map
        for i=1:num_goal
            istr = num2str(i);
            figure('Name', ['Optimized Camera' istr] );
            optimized_img = imread([output_img_folder 'optimized-Cam' istr ...
                '.tif']);
            imshow(optimized_img(:,:,1:3));
        end
        plotHeatMap( heat_map );
        return;
    end
catch ME
    if(isBatchMode())
        disp(getReport(ME));
        if(exist('logfile', 'var') && exist('output_img_folder', 'var'))
            move_file( logfile, [output_img_folder 'matlab.log'] );
        end
        exit;
    else
        rethrow(ME);
    end
end
end