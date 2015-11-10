% Script that performs a heat map reconstruction from a goal image
%% Clean state for the script

clear all;
close all;

%% Parameter initalization
% N.B. If Matlab is started from the GUI and custom paths are used for the
% Maya plugins, Matlab will not read the Maya path variables that were
% defined in the .bashrc file and the render script will fail, a
% workouround is to redefine them here:
% setenv('MAYA_SCRIPT_PATH', 'scripts path');
% setenv('MI_CUSTOM_SHADER_PATH', ' shaders include path');
% setenv('MI_LIBRARY_PATH', 'shaders path');

max_ite = 50; % Num of maximum iterations
epsilon = 100; % Error tolerance

project_path = '~/maya/projects/fire/';
scene_name = 'test68_spectrum_fix_propane';
raw_file_path = 'data/from_dmitry/vox_bin_00850.raw';
scene_img_folder = [project_path 'images/' scene_name '/'];
goal_img_path = [scene_img_folder 'goalimage.tif'];
goal_img = imread(goal_img_path);
goal_img = goal_img(:,:,1:3); % Transparency is not used, so ignore it


%% Avoid data overwrites by always creating a new folder
try
    % Find the last folder
    dir_num = 0;
    while(exist([scene_img_folder 'attr_search_' num2str(dir_num)], 'dir') == 7)
        dir_num = dir_num + 1;
    end
    
    % Create a new folder to store the data
    output_img_folder = [scene_img_folder 'attr_search_' num2str(dir_num) '/'];
    output_img_folder_name = ['attr_search_' num2str(dir_num) '/'];
    output_data_file = [output_img_folder 'fire_attributes.txt'];
    summary_file = [output_img_folder 'summary_file.txt'];
    disp(['Creating new output folder ' output_img_folder]);
    system(['mkdir ' output_img_folder]);
    
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
    system([currentFolder '/runMayaBatch.sh &']);
    
    % Set project to fire project directory
    cmd = 'setProject \""$HOME"/maya/projects/fire\"';
    if(~sendToMaya(cmd, sendMayaScript))
        disp('Could not send Maya command');
        return;
    end
    
    % Open our test scene
    cmd = ['file -open \"scenes/' scene_name '.ma\"'];
    if(~sendToMaya(cmd, sendMayaScript))
        disp('Could not send Maya command');
        return;
    end
    
    %% Genetic call
    
    % Wrap the fitness function into an anonymous function whose only
    % parameter is the heat map
    fitness_foo = @(x)heat_map_fitness(x, init_heat_map.xyz, scene_name, ...
        scene_img_folder, output_img_folder_name, sendMayaScript, goal_img);
    
    %% Options for the ga
    % Get default values
    options = gaoptimset(@ga);
    options.Generations = max_ite;
    options.PopulationSize = 10;
    options.EliteCount = 1;
    options.TimeLimit = 24 * 60 * 60; % In seconds
    options.Display = 'iter'; % Give some output on each iteration
    options.MutationFcn = @mutationadaptfeasible;
    
    %% Parameters bounds
    A = [];
    b = [];
    Aeq = [];
    beq = [];
    
    % Lower bounds, no less than 1200K -> 800C
    LB = ones(1, init_heat_map.size) * 10000;
    
    % Upper bounds, no more than 10000K
    UB = ones(1, init_heat_map.size) * 10000;
    
    nonlcon = [];
    
    tTotalStart = tic;
    %% Call the genetic algorithm optimization
    [heat_map_v, best_error, exitflag] = ga(fitness_foo, init_heat_map.size, ...
        A, b, Aeq, beq, LB, UB, nonlcon, options);
    
    % ga outputs a row vector, but we are working with column vectors
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
    if(~sendToMaya(cmd, sendMayaScript))
        disp('Could not send Maya command');
        return;
    end
    
    %% Set the folder and name of the render image
    cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
    cmd = [cmd scene_name '/' output_img_folder_name 'optimized' '\"'];
    if(~sendToMaya(cmd, sendMayaScript))
        disp('Could not send Maya command');
        return;
    end
    
    %% Render the image
    tic;
    cmd = 'Mayatomr -render -camera \"camera1\" -renderVerbosity 5 -logFile';
    if(~sendToMaya(cmd, sendMayaScript, 1))
        renderImgPath = [scene_img_folder output_img_folder_name ];
        disp(['Render error, check the logs in ' renderImgPath '*.log']);
        closeMayaAndMoveMRLog(sendMayaScript, renderImgPath);
        return;
    end
    disp(['Image rendered in ' num2str(toc) ]);
    
    %% Resource clean up after execution
    
    renderImgPath = [scene_img_folder output_img_folder_name ];
    closeMayaAndMoveMRLog(sendMayaScript, renderImgPath);
    
    % If running in batch mode, exit matlab
    if(isBatchMode())
        system(['mv matlab.log ' output_img_folder 'matlab.log']);
        disp(['Matlab log file saved in ' output_img_folder 'matlab.log']);
        exit;
    else
        return;
    end
catch ME
    
    renderImgPath = [scene_img_folder output_img_folder_name ];
    closeMayaAndMoveMRLog(sendMayaScript, renderImgPath);
    
    if(isBatchMode())
        disp(getReport(ME));
        if(exist('matlab.log', 'file'))
            system(['mv matlab.log ' output_img_folder 'matlab.log']);
            disp(['Matlab log file saved in ' output_img_folder 'matlab.log']);
        end
        exit;
    else
        rethrow(ME);
    end
end