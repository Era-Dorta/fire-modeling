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

% To modigy parameters specific to each solver go to the
% do_<solver>_solve() function

project_path = '~/maya/projects/fire/';
scene_name = 'test79_like_78_rot';
raw_file_path = 'data/heat_maps/gaussian4x4x4.raw';
scene_img_folder = [project_path 'images/' scene_name '/'];

% For single goal image the Maya scene must have only one renderable
% camera, for multiple goal images, it is assumed that there are as many
% cameras in the scene as goal images. If there are more cameras they must
% have the rendererable attribute set to false. Each camera must be named
% as "cameraNShape". The first goal image belongs to camera1Shape, the
% second to camera2Shape and so on.
goal_img_path = {[scene_img_folder 'goalimage1.tif']};

goal_mask_img_path = [scene_img_folder 'googlefire1.tif'];

mask_img_path = [scene_img_folder 'goalimage.tif'];

% Checks for number of goal images
if(~iscell(goal_img_path))
    num_goal = 1;
else
    if(numel(goal_img_path) == 1)
        goal_img_path = goal_img_path{1};
        num_goal = 1;
    else
        num_goal = numel(goal_img_path);
    end
end

if(num_goal == 1)
    % Error function to be used for the fitness function, it must accept two
    % images and return an error value
    error_foo = {@histogramErrorOpti};
else
    % Error function for multiple goal images
    error_foo = {@histogramErrorOptiN};
end
errorFooCloseObj = onCleanup(@() clear(func2str(error_foo{:})));

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
        'output_folder',  output_img_folder);
    mrLogPath = [scene_img_folder output_img_folder_name 'mentalray.log'];
    
    % Read goal image/s
    if(num_goal == 1)
        goal_img = imread(goal_img_path);
        goal_img = goal_img(:,:,1:3); % Transparency is not used, so ignore it
    else
        goal_img = cell(numel(goal_img_path), 1);
        for i=1:numel(goal_img_path)
            goal_img{i} = imread(goal_img_path{i});
            goal_img{i} = goal_img{i}(:,:,1:3); % Transparency is not used, so ignore it
        end
    end
    
    %%  Read mask images
    img_mask = imread(mask_img_path);
    img_mask = img_mask(:,:,1:3);
    
    % Valid pixels are the ones that are not black
    img_mask = (img_mask(:,:,1) > 0 & img_mask(:,:,2) > 0 & img_mask(:,:,3) > 0);
    
    goal_img_mask = imread(goal_mask_img_path);
    goal_img_mask = goal_img_mask(:,:,1:3);
    
    % Valid pixels are the ones that are not black
    goal_img_mask = (goal_img_mask(:,:,1) > 0 & goal_img_mask(:,:,2) > 0 ...
        & goal_img_mask(:,:,3) > 0);
    
    if(isequal(error_foo{1}, @MSE))
        % For MSE the goal and the render image have to be same size
        goal_img = imresize(goal_img, size(img_mask));
        goal_img_mask = imresize(goal_img_mask, size(img_mask));
        
        % MSE uses an RGB mask, the other error functions use a single
        % channel image mask
        img_mask(:,:,2) = img_mask;
        img_mask(:,:,3) = img_mask(:,:,2);
    end
    
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
    system(['mkdir ' output_img_folder ' < /dev/null']);
    
    %% Fitness function definition
    
    % Wrap the fitness function into an anonymous function whose only
    % parameter is the heat map
    if(numMayas == 1)
        % If there is only one Maya do not use the parallel fitness foo
        if(num_goal == 1)
            fitness_foo = @(x)heat_map_fitness(x, init_heat_map.xyz,  ...
                init_heat_map.size, error_foo, scene_name, scene_img_folder,  ...
                output_img_folder_name, sendMayaScript, ports, mrLogPath, ...
                goal_img, img_mask);
            
            fitnessFooCloseObj = onCleanup(@() clear('heat_map_fitness'));
        else
            fitness_foo = @(x)heat_map_fitnessN(x, init_heat_map.xyz,  ...
                init_heat_map.size, error_foo, scene_name, scene_img_folder,  ...
                output_img_folder_name, sendMayaScript, ports, mrLogPath, ...
                goal_img, img_mask);
            
            fitnessFooCloseObj = onCleanup(@() clear('heat_map_fitnessN'));
        end
    else
        fitness_foo = @(x)heat_map_fitness_par(x, init_heat_map.xyz,  ...
            init_heat_map.size, error_foo, scene_name, scene_img_folder,  ...
            output_img_folder_name, sendMayaScript, ports, mrLogPath, ...
            goal_img, img_mask);
        
        % heat_map_fitness uses a cache with persisten variables, after
        % optimizing delete the cache
        if(num_goal == 1)
            fitnessFooCloseObj = onCleanup(@() clear('heat_map_fitness'));
            fitnessFooCloseObjPar = onCleanup(@() parfevalOnAll(gcp, @clear, 0, ...
                'heat_map_fitness'));
        else
            fitnessFooCloseObj = onCleanup(@() clear('heat_map_fitnessN'));
            fitnessFooCloseObjPar = onCleanup(@() parfevalOnAll(gcp, @clear, 0, ...
                'heat_map_fitnessN'));
        end
        
        % If we are running in parallel also add parallel cleanup for the
        % erro function
        errorFooCloseObjPar = onCleanup(@() parfevalOnAll(gcp, @clear, 0, ...
            func2str(error_foo{:})));
    end
    
    %% Summary extra data
    if(num_goal == 1)
        goal_img_summay = goal_img_path;
    else
        % If there are several images, convert them into a string to put in
        % the summary data struct
        goal_img_summay = strjoin(goal_img_path, ', ');
    end
    summary_data = struct('GoalImage', goal_img_summay, 'MayaScene', ...
        [project_path 'scenes/' scene_name '.ma'], 'ErrorFc', ...
        func2str(error_foo{:}), 'NumMaya', numMayas);
    
    %% Solver call
    disp('Launching optimization algorithm');
    switch solver
        case 'ga'
            [heat_map_v, ~, ~] = do_genetic_solve( max_ite, ...
                time_limit, LB, UB, init_heat_map, fitness_foo, ...
                paths_str, summary_data, goal_img, goal_img_mask);
        case 'sa'
            [heat_map_v, ~, ~] = do_simulanneal_solve( ...
                max_ite, time_limit, LB, UB, init_heat_map, fitness_foo, ...
                summary_file, summary_data);
        case 'ga-re'
            % For the solve with reconstruction the size changes so leave
            % those two parameters open, so the function can modify them.
            % Let the solver use a different cache for each fitness foo
            fitness_foo = @(v, xyz, whd)heat_map_fitness(v, xyz, whd, ...
                error_foo, scene_name, scene_img_folder, output_img_folder_name, ...
                sendMayaScript, ports, mrLogPath, goal_img);
            
            % Extra paths needed in the solver
            paths_str.imprefixpath = [scene_name '/' output_img_folder_name];
            paths_str.mrLogPath = mrLogPath;
            
            [heat_map_v, ~, ~] = do_genetic_solve_resample( max_ite, ...
                time_limit, LB, UB, init_heat_map, fitness_foo, ...
                paths_str, sendMayaScript, ports, summary_data);
        case 'grad'
            [heat_map_v, ~, ~] = do_gradient_solve( ...
                max_ite, time_limit, LB, UB, init_heat_map, fitness_foo, ...
                summary_file, summary_data);
        case 'cmaes'
            % CMAES gets the data in column order so transpose it for it
            % to work
            if(numMayas == 1)
                % If there is only one Maya do not use the parallel fitness foo
                if(num_goal == 1)
                    fitness_foo = @(x)heat_map_fitness(x', init_heat_map.xyz,  ...
                        init_heat_map.size, error_foo, scene_name, scene_img_folder,  ...
                        output_img_folder_name, sendMayaScript, ports, mrLogPath, ...
                        goal_img);
                else
                    fitness_foo = @(x)heat_map_fitnessN(x', init_heat_map.xyz,  ...
                        init_heat_map.size, error_foo, scene_name, scene_img_folder,  ...
                        output_img_folder_name, sendMayaScript, ports, mrLogPath, ...
                        goal_img);
                end
            else
                fitness_foo = @(x)heat_map_fitness_par(x', init_heat_map.xyz,  ...
                    init_heat_map.size, error_foo, scene_name, scene_img_folder,  ...
                    output_img_folder_name, sendMayaScript, ports, mrLogPath, ...
                    goal_img);
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
    
    %% Add single view fitness value for multigoal optimization
    if(num_goal > 1)
        L = load([paths_str.summary '.mat']);
        
        c_img = imread([output_img_folder '/optimized1.tif']);
        c_img = c_img(:,:,1:3); % Transparency is not used, so ignore it
        
        clear(func2str(error_foo{1}));
        L.summary_data.ImageErrorSingleView = feval(error_foo{1}, goal_img(1), ...
            {c_img}, img_mask);
        
        summary_data = L.summary_data;
        save([paths_str.summary '.mat'], 'summary_data', '-append');
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
    
    %% Resource clean up after execution
    
    % If running in batch mode, exit matlab
    if(isBatchMode())
        move_file( logfile, [output_img_folder 'matlab.log'] );
        exit;
    else
        % If GUI running, show the computed heat map
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