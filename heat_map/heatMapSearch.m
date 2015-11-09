% Script that performs a heat map reconstruction from a goal image
%% Initialization all

clear all;
close all;

%%
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
scene_img_folder = [project_path 'images/' scene_name '/'];
goal_img_path = [scene_img_folder 'goalimage.tif'];
goal_img = imread(goal_img_path);
goal_img = goal_img(:,:,1:3); % Transparency is not used, so ignore it

try
    %% Avoid data overwrites by always creating a new folder
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
    
    %% Send script initialization
    % Render script is located on the same folder as this file
    [currentFolder,~,~] = fileparts(mfilename('fullpath'));
    sendMayaScript = [currentFolder '/sendMaya.rb'];
      
    % <densityScale> <densityOffset> <temperatureScale> <temperatureOffset> <intensity> <transparency>
    fire_attr = zeros(6, 1);
    
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
    
    [~, tmpdir] = system(['mktemp -d ' output_img_folder 'dirXXXXXX']);
    [~,tmpdirName,~] = fileparts(tmpdir);
    % Remove end on line characters
    tmpdirName = regexprep(tmpdirName,'\r\n|\n|\r','');
    
    % Set the folder and name of the render image
    cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
    cmd = [cmd scene_name '/' output_img_folder_name tmpdirName '/fireimage' '\"'];
    if(~sendToMaya(cmd, sendMayaScript))
        disp('Could not send Maya command');
        return;
    end   
    
    tic;
    cmd = 'Mayatomr -render -camera \"camera1\" -renderVerbosity 5 -logFile';
    if(~sendToMaya(cmd, sendMayaScript))
        disp('Could not send Maya command');
        return;
    end
    disp(['Image rendered in ' num2str(toc) ]);
    
    %% Render the best image again    
    best_im_path = [output_img_folder 'optimized.tif'];
    disp(['Rendering final image in ' best_im_path ]);
    
    % Set the folder and name of the render image
    cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
    cmd = [cmd scene_name '/' output_img_folder_name 'optimized' '\"'];
    if(~sendToMaya(cmd, sendMayaScript))
        disp('Could not send Maya command');
        return;
    end
    
    tic;
    cmd = 'Mayatomr -render -camera \"camera1\" -renderVerbosity 5 -logFile';
    if(~sendToMaya(cmd, sendMayaScript))
        disp(['Render error, check the logs in ' output_img_folder '*.log']);
        return;
    end
    disp(['Image rendered in ' num2str(toc) ]);
    
    %% After execution resource clean up
    % close Maya
    cmd = 'quit -f';
    sendToMaya(cmd, sendMayaScript); 
    
    % If running in batch mode, exit matlab
    if(isBatchMode())
        system(['mv matlab.log ' output_img_folder 'matlab.log']);
        disp(['Matlab log file saved in ' output_img_folder 'matlab.log']);
        exit;
    else
        return;
    end
catch ME
    cmd = 'quit -f';
    sendToMaya(cmd, sendMayaScript);
        
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