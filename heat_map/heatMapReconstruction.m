function heatMapReconstruction(solver, ports, logfile)
%HEATMAPRECONSTRUCTION Performs a heat map reconstruction from a goal image
%   HEATMAPRECONSTRUCTION(SOLVER, PORTS, LOGFILE)
%   SOLVER should be one of the following
%   'ga' -> Genetic Algorithm
%   'sa' -> Simulated Annealing
%   'ga-re' -> Genetic Algorithm with heat map resampling
%   'grad' -> Gradient Descent
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

rand_seed = 'default';
rng(rand_seed);

% To modify parameters specific to each solver go to the relevant
% do_<solver>_solve() function

max_ite = 1000; % Num of maximum iterations
% epsilon = 100; % Error tolerance, using Matlab default's at the moment
LB = 300; % Lower bounds, no less than 300K -> 27C
UB = 2000; % Upper bounds, no more than 2000K -> 1727C
time_limit = 24 * 60 * 60; % In seconds
use_approx_fitness = false; % Using the approximate fitness function?

multi_goal = false; % Select a test to run, to be removed
symmetric = true; % Select a test to run, to be removed

% Distance function for the histogram error functions, any of the ones in
% the folder error_fnc/distance_fnc
% Common ones: histogram_sum_abs, histogram_intersection,
% chi_square_statistics_fast
dist_foo = @histogram_sum_abs;

% Error function used in the fitness function
% One of: histogramErrorOpti, histogramDErrorOpti, MSE
error_foo = {@histogramErrorOpti};

% If use_approx_fitness is true, this function will be used in the fitness
% function, the one above one will used only to check the final result
approx_error_foo = @histogramErrorApprox;

%% Setting maing paths and clean up functions
scene_name = 'test95_gaussian_new';

[project_path, raw_file_path, scene_img_folder, goal_img_path, ...
    goal_mask_img_path, mask_img_path] = get_test_paths(scene_name, ...
    multi_goal, symmetric);

num_goal = numel(goal_img_path);

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
    while(exist([scene_img_folder 'hm_search_' num2str(dir_num)], 'dir') == 7)
        dir_num = dir_num + 1;
    end
    
    % Create a new folder to store the data
    output_img_folder = [scene_img_folder 'hm_search_' num2str(dir_num) '/'];
    output_img_folder_name = ['hm_search_' num2str(dir_num) '/'];
    summary_file = [output_img_folder 'summary_file'];
    % It will be saved as fig and tiff
    error_figure = [output_img_folder 'error_function'];
    paths_str = struct('summary',  summary_file, 'errorfig', error_figure, ...
        'output_folder',  output_img_folder, 'ite_img', [output_img_folder  ...
        'current1-Cam']);
    maya_log = [scene_img_folder output_img_folder_name 'maya.log'];
    
    %% Read goal and mask image/s
    % For MSE resize the goal image to match the synthetic image
    if(isequal(error_foo{1}, @MSE))
        resize_goal = true;
    else
        resize_goal = false;
    end
    [ goal_img, goal_mask, img_mask ] = readGoalAndMask( goal_img_path, ...
        mask_img_path, goal_mask_img_path, resize_goal);
    
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
    init_heat_map = read_raw_file([project_path raw_file_path]);
    
    %% Maya initialization
    
    for i=1:numMayas
        disp(['Loading scene in Maya:' num2str(ports(i))]);
        % Set project to fire project directory
        cmd = 'setProject \""$HOME"/maya/projects/fire\"';
        maya_send{i}(cmd, 0);
        
        % Open our test scene
        cmd = ['file -open -force \"scenes/' scene_name '.ma\"'];
        maya_send{i}(cmd, 0);
        
        % Force a frame update, as batch rendering later does not do it, this
        % will fix any file name errors due to using the same scene on
        % different computers
        cmd = '\$ctime = \`currentTime -query\`; currentTime 1; currentTime \$ctime';
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
    mkdir(scene_img_folder, output_img_folder_name);
    
    %% Summary extra data
    
    % If there are several images, convert them into a string to put in
    % the summary data struct
    goal_img_summay = strjoin(goal_img_path, ', ');
    
    summary_data = struct('GoalImage', goal_img_summay, 'MayaScene', ...
        [project_path 'scenes/' scene_name '.ma'], 'ErrorFnc', ...
        func2str(error_foo{:}), 'DistFnc', func2str(dist_foo), ...
        'NumMaya', numMayas);
    
    %% Fitness function definition
    
    % Encapsulate the distance function in the error function
    error_foo{1} = @(x) error_foo{1}(goal_img, x, goal_mask, img_mask, ...
        dist_foo);
    
    % Wrap the fitness function into an anonymous function whose only
    % parameter is the heat map
    if(use_approx_fitness)
        summary_data.FinalErrorFnc = summary_data.ErrorFnc;
        summary_data.ErrorFnc = func2str(approx_error_foo);
        
        approx_error_foo = @(x) approx_error_foo(x, goal_img, goal_mask, ...
            dist_foo);
        
        fitness_foo = @(x)heat_map_fitness_approx(x, init_heat_map.xyz, ...
            init_heat_map.size, approx_error_foo, LB, UB);
    else
        fitness_foo = @(x)heat_map_fitness_par(x, init_heat_map.xyz,  ...
            init_heat_map.size, error_foo, scene_name, scene_img_folder,  ...
            output_img_folder_name, maya_send, num_goal, LB, UB);
    end
    
    %% Solver call
    disp('Launching optimization algorithm');
    switch solver
        case 'ga'
            [heat_map_v, ~, ~] = do_genetic_solve( max_ite, ...
                time_limit, LB, UB, init_heat_map, fitness_foo, ...
                paths_str, summary_data, goal_img, goal_mask);
        case 'sa'
            [heat_map_v, ~, ~] = do_simulanneal_solve( ...
                max_ite, time_limit, LB, UB, init_heat_map, fitness_foo, ...
                paths_str, summary_data);
        case 'ga-re'
            % For the solve with reconstruction the size changes so leave
            % those two parameters open, so the function can modify them.
            % Let the solver use a different cache for each fitness foo
            if(use_approx_fitness)
                fitness_foo = @(v, xyz, whd)heat_map_fitness_approx(v, xyz, ...
                    whd, approx_error_foo, LB, UB);
            else
                fitness_foo = @(v, xyz, whd)heat_map_fitness_par(v, xyz, ...
                    whd, error_foo, scene_name, scene_img_folder,  ...
                    output_img_folder_name, maya_send, num_goal, LB, UB);
            end
            
            % Extra paths needed in the solver
            paths_str.imprefixpath = [scene_name '/' output_img_folder_name];
            
            [heat_map_v, ~, ~] = do_genetic_solve_resample( max_ite, ...
                time_limit, LB, UB, init_heat_map, fitness_foo, ...
                paths_str, maya_send, num_goal, summary_data);
        case 'grad'
            [heat_map_v, ~, ~] = do_gradient_solve( ...
                max_ite, time_limit, LB, UB, init_heat_map, fitness_foo, ...
                paths_str, summary_data);
        case 'cmaes'
            % CMAES gets the data in column order so transpose it for it
            % to work
            if(use_approx_fitness)
                fitness_foo = @(x)heat_map_fitness_approx(x',  ...
                    init_heat_map.xyz, init_heat_map.size,  ...
                    approx_error_foo, LB, UB);
            else
                fitness_foo = @(x)heat_map_fitness_par(x', init_heat_map.xyz,  ...
                    init_heat_map.size, error_foo, scene_name, scene_img_folder,  ...
                    output_img_folder_name, maya_send, num_goal, LB, UB);
            end
            
            heat_map_v = do_cmaes_solve( max_ite, ...
                time_limit, LB, UB, init_heat_map, fitness_foo, ...
                paths_str, summary_data, numMayas > 1);
        case 'lhs'
            heat_map_v = do_lhs_solve( max_ite, time_limit, LB, UB, ...
                init_heat_map, fitness_foo, paths_str, summary_data);
        otherwise
            solver_names = '[''ga'', ''sa'', ''ga-re'', ''grad'', ''cmaes'']';
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
        cmd = [cmd scene_name '/' output_img_folder_name 'optimized-Cam' ...
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
    if(use_approx_fitness)
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
    
    %% Render the initial population in a folder
    % With the ga-re solver there are several initial population files so
    % avoid the rendering in that case
    if ~any(strcmp(solver, {'ga-re', 'lhs'}))
        L = load([paths_str.output_folder 'InitialPopulation.mat']);
        
        disp(['Rendering the initial population in ' scene_img_folder ...
            output_img_folder_name 'InitialPopulationCam<d>' ]);
        
        if( strcmp(solver,'cmaes'))
            % Transpose to get row order as the cmaes initial population is
            % in column order
            L.InitialPopulation = L.InitialPopulation';
        end
        
        for i=1:num_goal
            istr = num2str(i);
            
            % Active current camera
            cmd = ['setAttr \"camera' istr 'Shape.renderable\" 1'];
            maya_send{1}(cmd, 0);
            
            render_heat_maps( L.InitialPopulation, init_heat_map.xyz, init_heat_map.size, ...
                scene_name, scene_img_folder, output_img_folder_name, ...
                ['InitialPopulationCam' istr], maya_send);
            
            % Deactive current camera
            cmd = ['setAttr \"camera' istr 'Shape.renderable\" 0'];
            maya_send{1}(cmd, 0);
        end
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