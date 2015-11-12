function heatMapSearch(solver, logfile)
% Function that performs a heat map reconstruction from a goal image
% Solver should be one of the following
% 'ga' -> Genetic Algorithms
% 'sa' -> Simulated Annealing
%% Parameter initalization
% N.B. If Matlab is started from the GUI and custom paths are used for the
% Maya plugins, Matlab will not read the Maya path variables that were
% defined in the .bashrc file and the render script will fail, a
% workouround is to redefine them here:
% setenv('MAYA_SCRIPT_PATH', 'scripts path');
% setenv('MI_CUSTOM_SHADER_PATH', ' shaders include path');
% setenv('MI_LIBRARY_PATH', 'shaders path');

is_maya_open = false; % Make sure not to close other users Maya instances

max_ite = 1500; % Num of maximum iterations
% epsilon = 100; % Error tolerance, using Matlab default's at the moment
time_limit = 24 * 60 * 60; % In seconds
LB = 1200; % Lower bounds, no less than 1200K -> 800C
UB = 10000; % Upper bounds, no more than 10400K -> 10000C

% To modigy parameters specific to each solver go to the
% do_<solver>_solve() function

project_path = '~/maya/projects/fire/';
scene_name = 'test68_spectrum_fix_propane';
raw_file_path = 'data/from_dmitry/vox_bin_00850.raw';
scene_img_folder = [project_path 'images/' scene_name '/'];
goal_img_path = [scene_img_folder 'goalimage.tif'];

%% Avoid data overwrites by always creating a new folder
try
    if(nargin == 0)
        error('Not enough input arguments.');
    end
    
    if(isBatchMode() && nargin < 2)
        error('Logfile name is required when running in batch mode');
    end
    
    % Find the last folder
    dir_num = 0;
    while(exist([scene_img_folder 'attr_search_' num2str(dir_num)], 'dir') == 7)
        dir_num = dir_num + 1;
    end
    
    % Create a new folder to store the data
    output_img_folder = [scene_img_folder 'attr_search_' num2str(dir_num) '/'];
    output_img_folder_name = ['attr_search_' num2str(dir_num) '/'];
    summary_file = [output_img_folder 'summary_file.txt'];
    mrLogPath = [scene_img_folder output_img_folder_name 'mentalray.log'];
    disp(['Creating new output folder ' output_img_folder]);
    system(['mkdir ' output_img_folder]);
    
    % Read goal image
    goal_img = imread(goal_img_path);
    goal_img = goal_img(:,:,1:3); % Transparency is not used, so ignore it
    
    %% SendMaya script initialization
    % Render script is located on the same folder as this file
    [currentFolder,~,~] = fileparts(mfilename('fullpath'));
    sendMayaScript = [currentFolder '/sendMaya.rb'];
    
    %% Volumetric data initialization
    init_heat_map = read_raw_file([project_path raw_file_path]);
    
    % As a good starting point make the mean at 2500K
    init_heat_map.v = init_heat_map.v * (2500 / mean(init_heat_map.v));
    
    %% Maya initialization
    % Launch Maya
    % TODO If another Matlab instance is run after we get the port but
    % before Maya opens, they would use the same port
    port = getNextFreePort();
    disp(['Launching Maya listening to port ' num2str(port)]);
    if(system([currentFolder '/runMayaBatch.sh ' num2str(port)]) ~= 0)
        error('Could not open Maya');
    end
    % Maya was launched successfully, so we are responsible for closing it
    is_maya_open = true;
    
    disp('Loading scene in Maya')
    % Set project to fire project directory
    cmd = 'setProject \""$HOME"/maya/projects/fire\"';
    sendToMaya(sendMayaScript, port, cmd);
    
    % Open our test scene
    cmd = ['file -open \"scenes/' scene_name '.ma\"'];
    sendToMaya(sendMayaScript, port, cmd);
    
    %% Fitness function definition
    
    % Wrap the fitness function into an anonymous function whose only
    % parameter is the heat map
    fitness_foo = @(x)heat_map_fitness(x, init_heat_map.xyz, scene_name, ...
        scene_img_folder, output_img_folder_name, sendMayaScript, port, ...
        mrLogPath, goal_img);
    
    %% Solver call
    disp('Launching optimization algorithm');
    switch solver
        case 'ga'
            [heat_map_v, ~, ~] = do_genetic_solve( max_ite, ...
                time_limit, LB, UB, init_heat_map.size, fitness_foo, ...
                summary_file);
        case 'sa'
            [heat_map_v, ~, ~] = do_simulanneal_solve( ...
                max_ite, time_limit, LB, UB, init_heat_map, fitness_foo, ...
                summary_file);
        otherwise
            error('Invalid solver, choose one of [''ga'',''sa'']');
    end
    
    % Solvers output a row vector, but we are working with column vectors
    heat_map_v = heat_map_v';
    
    %%  Render the best image again
    % Set the path for the image
    best_im_path = [output_img_folder 'optimized.tif'];
    disp(['Rendering final image in ' best_im_path ]);
    
    %% Save the best heat map in a raw file
    heat_map_path = [output_img_folder '/heat-map.raw'];
    heat_map = struct('xyz', init_heat_map.xyz, 'v', heat_map_v, 'size', init_heat_map.size);
    save_raw_file(heat_map_path, heat_map);
    
    %% Set the heat map file as temperature file
    % It cannot have ~, and it has to be the full path, so use the HOME var
    cmd = 'setAttr -type \"string\" fire_volume_shader.temperature_file \"';
    cmd = [cmd '$HOME/' output_img_folder(3:end) 'heat-map.raw\"'];
    sendToMaya(sendMayaScript, port, cmd);
    
    %% Set the folder and name of the render image
    cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
    cmd = [cmd scene_name '/' output_img_folder_name 'optimized' '\"'];
    sendToMaya(sendMayaScript, port, cmd);
    
    %% Render the image
    tic;
    cmd = 'Mayatomr -render -camera \"camera1\" -renderVerbosity 5';
    sendToMaya(sendMayaScript, port, cmd, 1, mrLogPath);
    disp(['Image rendered in ' num2str(toc) ]);
    
    %% Resource clean up after execution
    
    closeMaya(sendMayaScript, port);
    
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
    
    if(is_maya_open)
        closeMaya(sendMayaScript, port);
    end
    
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