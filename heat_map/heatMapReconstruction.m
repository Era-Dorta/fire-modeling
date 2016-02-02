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
UB = 10000; % Upper bounds, no more than 10000K -> 9727C
time_limit = 24 * 60 * 60; % In seconds

% To modigy parameters specific to each solver go to the
% do_<solver>_solve() function

project_path = '~/maya/projects/fire/';
scene_name = 'test79_like_78_rot';
raw_file_path = 'data/heat_maps/gaussian4x4x4.raw';
scene_img_folder = [project_path 'images/' scene_name '/'];
goal_img_path = [scene_img_folder 'goalimage.tif'];

% Error function to be used for the fitness function, it must accept two
% images and return an error value
error_foo = {@histogramErrorOpti};
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
    
    % Read goal image
    goal_img = imread(goal_img_path);
    goal_img = goal_img(:,:,1:3); % Transparency is not used, so ignore it
    
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
        disp('Loading scene in Maya')
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
    end
    
    %% Ouput folder
    disp(['Creating new output folder ' output_img_folder]);
    system(['mkdir ' output_img_folder ' < /dev/null']);
    
    %% Fitness function definition
    
    % Wrap the fitness function into an anonymous function whose only
    % parameter is the heat map
    if(numMayas == 1)
        % If there is only one Maya do not use the parallel fitness foo
        fitness_foo = @(x)heat_map_fitness(x, init_heat_map.xyz,  ...
            init_heat_map.size, error_foo, scene_name, scene_img_folder,  ...
            output_img_folder_name, sendMayaScript, ports, mrLogPath, ...
            goal_img);
    else
        fitness_foo = @(x)heat_map_fitness_par(x, init_heat_map.xyz,  ...
            init_heat_map.size, error_foo, scene_name, scene_img_folder,  ...
            output_img_folder_name, sendMayaScript, ports, mrLogPath, ...
            goal_img);
    end
    % heat_map_fitness uses a cache with persisten variables, after
    % optimizing delete the cache
    fitnessFooCloseObj = onCleanup(@() clear('heat_map_fitness'));
    
    %% Summary extra data
    summary_data = struct('GoalImage', goal_img_path, 'MayaScene', ...
        [project_path 'scenes/' scene_name '.ma'], 'ErrorFc', ...
        func2str(error_foo{:}), 'NumMaya', numMayas);
    
    %% Solver call
    disp('Launching optimization algorithm');
    switch solver
        case 'ga'
            [heat_map_v, ~, ~] = do_genetic_solve( max_ite, ...
                time_limit, LB, UB, init_heat_map, fitness_foo, ...
                paths_str, summary_data);
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
        otherwise
            solver_names = '[''ga'', ''sa'', ''ga-re'', ''grad'']';
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
    
    % Set the folder and name of the render image
    cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
    cmd = [cmd scene_name '/' output_img_folder_name 'optimized' '\"'];
    sendToMaya(sendMayaScript, ports(1), cmd);
    
    disp(['Rendering final image in ' output_img_folder 'optimized.tif' ]);
    
    % Render the image
    tic;
    cmd = 'Mayatomr -render -camera \"camera1\" -renderVerbosity 5';
    sendToMaya(sendMayaScript, ports(1), cmd, 1, mrLogPath);
    disp(['Image rendered in ' num2str(toc) ]);
    
    %% Render the initial population in a folder
    % With the ga-re solver there are several initial population files so
    % avoid the rendering in that case
    if ~strcmp(solver, 'ga-re')
        load([paths_str.output_folder 'InitialPopulation.mat']);
        
        disp(['Rendering the initial population in ' scene_img_folder ...
            output_img_folder_name 'InitialPopulation' ]);
        
        render_heat_maps( InitialPopulation, init_heat_map.xyz, init_heat_map.size, ...
            scene_name, scene_img_folder, output_img_folder_name, 'InitialPopulation', ...
            sendMayaScript, ports(1), mrLogPath);
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