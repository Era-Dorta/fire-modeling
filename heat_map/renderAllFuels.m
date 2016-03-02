function renderAllFuels(port, logfile)
%RENDERALLFUELS Render maya scene
%   RENDERALLFUELS(PORT, LOGFILE) Renders an image for each fuel type for
%   the scene described in a the variable scene_name. PORT is the port a
%   Maya instance is listening to. If running in batch mode a LOGFILE is
%   required

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

project_path = '~/maya/projects/fire/';
% scene_name = 'test84';
scene_name = 'test86_multiple_flames';
% scene_name =  'test88_like_86_pretonemap';
scene_img_folder = [project_path 'images/' scene_name '/'];

%% Avoid data overwrites by always creating a new folder
try
    if(nargin > 2)
        error('Too many input arguments.');
    end
    
    if(isBatchMode() && nargin < 1)
        error('Logfile name is required when running in batch mode');
    end
    
    % Find the last folder
    dir_num = 0;
    while(exist([scene_img_folder 'render_fuels_test' num2str(dir_num)], 'dir') == 7)
        dir_num = dir_num + 1;
    end
    
    % Create a new folder to store the data
    output_img_folder = [scene_img_folder 'render_fuels_test' num2str(dir_num) '/'];
    output_img_folder_name = ['render_fuels_test' num2str(dir_num) '/'];
    mrLogPath = [scene_img_folder output_img_folder_name 'mentalray.log'];
    
    %% SendMaya script initialization
    % Render script is located in the same maya_comm folder
    [currentFolder,~,~] = fileparts(mfilename('fullpath'));
    sendMayaScript = [currentFolder '/maya_comm/sendMaya.rb'];
    
    %% Maya initialization
    % Render script is located in the same maya_comm folder
    [currentFolder,~,~] = fileparts(mfilename('fullpath'));
    sendMayaScript = [currentFolder '/maya_comm/sendMaya.rb'];
    
    disp('Loading scene in Maya')
    % Set project to fire project directory
    cmd = 'setProject \""$HOME"/maya/projects/fire\"';
    sendToMaya(sendMayaScript, port, cmd);
    
    % Open our test scene
    cmd = ['file -force -open \"scenes/' scene_name '.ma\"'];
    sendToMaya(sendMayaScript, port, cmd);
    
    % Force a frame update, as batch rendering later does not do it, this
    % will fix any file name errors due to using the same scene on
    % different computers
    cmd = '\$ctime = \`currentTime -query\`; currentTime 1; currentTime \$ctime';
    sendToMaya(sendMayaScript, port, cmd);
    
    %% Ouput folder
    disp(['Creating new output folder ' output_img_folder]);
    system(['mkdir ' output_img_folder]);
    
    %% Render each image
    total_time = 0;
    
    % Fuel names and fuel indices in Maya
    fuel_name = {'BlackBody', 'Propane', 'Acetylene', 'Cu', 'S', 'Li', 'Ba', 'Na', 'Co', 'Sc' };
    fuel_index =0:9;
    
    totalSize = numel(fuel_index);
    
    for i=1:totalSize
        starttic = tic;
        
        istr = sprintf('%d', fuel_index(i));
        
        % Set the fuel type
        cmd = ['setAttr fire_volume_shader.fuel_type ' istr];
        sendToMaya(sendMayaScript, port, cmd);
        
        % Set the folder and name of the render image
        cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
        cmd = [cmd scene_name '/' output_img_folder_name istr '-' fuel_name{i} '-' scene_name '\"'];
        sendToMaya(sendMayaScript, port, cmd);
        
        % Render the image
        cmd = 'Mayatomr -render -renderVerbosity 2';
        sendToMaya(sendMayaScript, port, cmd, 1, mrLogPath);
        
        % Estimate the remaining time
        c_time = toc(starttic);
        total_time = total_time + c_time;
        mean_time = total_time / (i);
        remaining_time = ((totalSize - (i)) * mean_time) / 86400;
        
        disp(['Image ' num2str(i) '/' num2str(totalSize) ' rendered, remaining time ' ...
            datestr(remaining_time, 'HH:MM:SS.FFF')]);
    end
    
    %% Resource clean up after execution
    
    % If running in batch mode, exit matlab
    if(isBatchMode())
        move_file( logfile, [output_img_folder 'matlab.log'] );
        exit;
    else
        return;
    end
catch ME
    if(isBatchMode())
        disp(getReport(ME));
        move_file( logfile, [output_img_folder 'matlab.log'] );
        exit;
    else
        rethrow(ME);
    end
end
end