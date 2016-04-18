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

max_ite = 1000; % Num of maximum iterations
% epsilon = 100; % Error tolerance, using Matlab default's at the moment
LB = 300; % Lower bounds, no less than 300K -> 27C
UB = 2000; % Upper bounds, no more than 2000K -> 1727C
time_limit = 24 * 60 * 60; % In seconds
use_approx_fitness = false;

% To modigy parameters specific to each solver go to the
% do_<solver>_solve() function

project_path = '~/maya/projects/fire/';
scene_name = 'test95_gaussian_new';
raw_file_path = 'data/heat_maps/gaussian4x4x4new.raw';
%raw_file_path = 'data/heat_maps/asymmetric4x4x4new.raw';
scene_img_folder = [project_path 'images/' scene_name '/'];

% For single goal image the Maya scene must have only one renderable
% camera, for multiple goal images, it is assumed that there are as many
% cameras in the scene as goal images. If there are more cameras they must
% have the rendererable attribute set to false. Each camera must be named
% as "cameraNShape". The first goal image belongs to camera1Shape, the
% second to camera2Shape and so on.
goal_img_path = {[scene_img_folder 'goalimage1.tif']};
goal_mask_img_path = {[scene_img_folder 'maskcam1.png']};
mask_img_path = {[scene_img_folder 'maskcam1.png']};

% goal_img_path = {[scene_img_folder 'goalimage1-asym.tif'], ...
%     [scene_img_folder 'goalimage2-asym.tif']};
% goal_mask_img_path = {[scene_img_folder 'maskcam1.png'], ...
%     [scene_img_folder 'maskcam2.png']};
% mask_img_path = {[scene_img_folder 'maskcam1.png'], ...
%     [scene_img_folder 'maskcam2.png']};

% goal_img_path = {[scene_img_folder 'goalimage1.tif'], ...
%     [scene_img_folder 'goalimage2.tif']};
% goal_mask_img_path = {[scene_img_folder 'maskcam1.png'], ...
%     [scene_img_folder 'maskcam2.png']};
% mask_img_path = {[scene_img_folder 'maskcam1.png'], ...
%     [scene_img_folder 'maskcam2.png']};

num_goal = numel(goal_img_path);

% Error function used in the fitness function
error_foo = {@histogramErrorOpti};

% List of function with persistent variables that need to be clean up after
% execution
clear_foo_str = {'histogramErrorOpti', ...
    'heat_map_fitness', 'heat_map_fitness_interp',  ...
    'render_attr_fitness', 'histogramEstimate', 'histogramErrorApprox', ...
    'gaxoverpriorhisto', 'gacrossovercombine'};

% Clear all the functions
clearCloseObj = onCleanup(@() clear(clear_foo_str{:}));
if(numel(ports) > 1)
    % If running of parallel, clear the functions in the workers as well
    clearParCloseObj = onCleanup(@() parfevalOnAll(gcp, @clear, 0, ...
        clear_foo_str{:}));
end

%% Avoid data overwrites by always creating a new folder
try
    if(nargin < 2)
        error('Not enough input arguments.');
    end
    
    if(isBatchMode() && nargin < 3)
        error('Logfile name is required when running in batch mode');
    end
    
    if(use_approx_fitness && isequal(error_foo{1}, @MSE))
        error('Approx fitness function can only be used with histogram error function');
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
        'best-' num2str(ports(1)) '.tif']);
    mrLogPath = [scene_img_folder output_img_folder_name 'mentalray.log'];
    
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
    
    %% Volumetric data initialization
    init_heat_map = read_raw_file([project_path raw_file_path]);
    
    %% Maya initialization
    % Each maya instance usually renders using 4 cores
    numMayas = numel(ports);
    
    for i=1:numMayas
        disp(['Loading scene in Maya:' num2str(ports(i))]);
        % Set project to fire project directory
        cmd = 'setProject \""$HOME"/maya/projects/fire\"';
        sendToMaya(sendMayaScript, ports(i), cmd);
        
        % Open our test scene
        cmd = ['file -open -force \"scenes/' scene_name '.ma\"'];
        sendToMaya(sendMayaScript, ports(i), cmd);
        
        % Force a frame update, as batch rendering later does not do it, this
        % will fix any file name errors due to using the same scene on
        % different computers
        cmd = '\$ctime = \`currentTime -query\`; currentTime 1; currentTime \$ctime';
        sendToMaya(sendMayaScript, ports(i), cmd);
        
        % Deactive all but the first camera if there is more than one goal
        % image
        for j=2:num_goal
            cmd = ['setAttr \"camera' num2str(j) 'Shape.renderable\" 0'];
            sendToMaya(sendMayaScript, ports(i), cmd);
        end
    end
    
    %% Ouput folder
    disp(['Creating new output folder ' output_img_folder]);
    mkdir(scene_img_folder, output_img_folder_name);
    
    %% Fitness function definition
    
    % Wrap the fitness function into an anonymous function whose only
    % parameter is the heat map
    if(use_approx_fitness)
        fitness_foo = @(x)heat_map_fitness_approx(x, goal_img, goal_mask);
    else
        fitness_foo = @(x)heat_map_fitness_par(x, init_heat_map.xyz,  ...
            init_heat_map.size, error_foo, scene_name, scene_img_folder,  ...
            output_img_folder_name, sendMayaScript, ports, mrLogPath, ...
            goal_img, goal_mask, img_mask, LB, UB);
    end
    
    %% Summary extra data
    
    % If there are several images, convert them into a string to put in
    % the summary data struct
    goal_img_summay = strjoin(goal_img_path, ', ');
    
    summary_data = struct('GoalImage', goal_img_summay, 'MayaScene', ...
        [project_path 'scenes/' scene_name '.ma'], 'ErrorFc', ...
        func2str(error_foo{:}), 'NumMaya', numMayas);
    
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
            if(~use_approx_fitness)
                fitness_foo = @(v, xyz, whd)heat_map_fitness_par(v, xyz, ...
                    whd, error_foo, scene_name, scene_img_folder,  ...
                    output_img_folder_name, sendMayaScript, ports, ...
                    mrLogPath, goal_img, goal_mask, img_mask);
            end
            
            % Extra paths needed in the solver
            paths_str.imprefixpath = [scene_name '/' output_img_folder_name];
            paths_str.mrLogPath = mrLogPath;
            
            [heat_map_v, ~, ~] = do_genetic_solve_resample( max_ite, ...
                time_limit, LB, UB, init_heat_map, fitness_foo, ...
                paths_str, sendMayaScript, ports, summary_data);
        case 'grad'
            [heat_map_v, ~, ~] = do_gradient_solve( ...
                max_ite, time_limit, LB, UB, init_heat_map, fitness_foo, ...
                paths_str, summary_data);
        case 'cmaes'
            % CMAES gets the data in column order so transpose it for it
            % to work
            if(use_approx_fitness)
                fitness_foo = @(x)heat_map_fitness_approx(x', goal_img, goal_mask);
            else
                fitness_foo = @(x)heat_map_fitness_par(x', init_heat_map.xyz,  ...
                    init_heat_map.size, error_foo, scene_name, scene_img_folder,  ...
                    output_img_folder_name, sendMayaScript, ports, mrLogPath, ...
                    goal_img, goal_mask, img_mask, LB, UB);
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
    sendToMaya(sendMayaScript, ports(1), cmd);
    
    disp(['Rendering final images in ' output_img_folder 'optimized<d>.tif' ]);
    
    for i=1:num_goal
        istr = num2str(i);
        
        % Active current camera
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 1'];
        sendToMaya(sendMayaScript, ports(1), cmd);
        
        % Set the folder and name of the render image
        cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
        cmd = [cmd scene_name '/' output_img_folder_name 'optimized' ...
            istr '\"'];
        sendToMaya(sendMayaScript, ports(1), cmd);
        
        % Render the image
        tic;
        cmd = 'Mayatomr -verbosity 2 -render -renderVerbosity 2';
        sendToMaya(sendMayaScript, ports(1), cmd, 1, mrLogPath);
        
        % Deactivate the current camera
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 0'];
        sendToMaya(sendMayaScript, ports(1), cmd);
    end
    
    %% Append the real error if using the approx fitness
    if(use_approx_fitness)
        L = load([paths_str.summary '.mat']);
        
        c_img = imread([output_img_folder '/optimized1.tif']);
        c_img = c_img(:,:,1:3); % Transparency is not used, so ignore it
        
        L.summary_data.RealError = sum(feval(error_foo{1},  ...
            goal_img(1), {c_img}, goal_mask(1), img_mask(1)));
        
        disp(['Real error ' num2str(L.summary_data.RealError)]);
        summary_data = L.summary_data;
        save([paths_str.summary '.mat'], 'summary_data', '-append');
        
        append_to_summary_file(paths_str.summary, ['Real error is '...
            num2str(L.summary_data.RealError)]);
    end
    
    %% Add single view fitness value for multigoal optimization
    if(num_goal > 1)
        L = load([paths_str.summary '.mat']);
        
        c_img = imread([output_img_folder '/optimized1.tif']);
        c_img = c_img(:,:,1:3); % Transparency is not used, so ignore it
        
        L.summary_data.ImageErrorSingleView = sum(feval(error_foo{1},  ...
            goal_img(1), {c_img}, goal_mask(1), img_mask(1)));
        
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
            sendToMaya(sendMayaScript, ports(1), cmd);
            
            render_heat_maps( L.InitialPopulation, init_heat_map.xyz, init_heat_map.size, ...
                scene_name, scene_img_folder, output_img_folder_name, ...
                ['InitialPopulationCam' istr], sendMayaScript, ports(1), ...
                mrLogPath);
            
            % Deactive current camera
            cmd = ['setAttr \"camera' istr 'Shape.renderable\" 0'];
            sendToMaya(sendMayaScript, ports(1), cmd);
        end
    end
    
    %% Move the best per iteration images to a folder
    mkdir([output_img_folder 'best-iter']);
    movefile([output_img_folder 'best-*.tif'], ...
        [output_img_folder 'best-iter']);
        
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
            optimized_img = imread([output_img_folder 'optimized' istr ...
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