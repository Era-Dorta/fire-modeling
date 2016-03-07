function createCTtable(port, logfile)
%CREATECTTABLE Create a precomputed color table
%   createCTtable(PORT, LOGFILE) Creates a precomputed table of colours
%   and temperatures for the scene described in a the variable scene_name.
%   PORT is the port a  Maya instance is listening to. If running in batch
%   mode a LOGFILE is required

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
scene_name = 'test89_bbr_table';
raw_file_path = 'data/heat_maps/constDensity3x3x3.raw';
scene_img_folder = [project_path 'images/' scene_name '/'];

temp_div = 25;
min_temp = 1000;
max_temp = 2000;

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
    while(exist([scene_img_folder 'ct_table' num2str(dir_num)], 'dir') == 7)
        dir_num = dir_num + 1;
    end
    
    % Create a new folder to store the data
    output_img_folder = [scene_img_folder 'ct_table' num2str(dir_num) '/'];
    output_img_folder_name = ['ct_table' num2str(dir_num) '/'];
    mrLogPath = [scene_img_folder output_img_folder_name 'mentalray.log'];
    
    %% Volumetric data initialization
    init_heat_map = read_raw_file([project_path raw_file_path]);
    
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
    
    % Set the scale to 0, so that we can control the temperature with the
    % offset regardless of the initial values in the raw file
    cmd = 'setAttr fire_volume_shader.temperature_scale 0';
    sendToMaya(sendMayaScript, port, cmd);
    
    %% Ouput folder
    disp(['Creating new output folder ' output_img_folder]);
    system(['mkdir ' output_img_folder]);
    
    %% Render each image
    total_time = 0;
    
    % Fuel names and fuel indices in Maya
    fuel_name = {'BlackBody', 'Propane', 'Acetylene', 'Cu', 'S', 'Li', 'Ba', 'Na', 'Co', 'Sc' };
    totalSize = numel(fuel_name);
    fuel_index =0:totalSize-1;
    
    temp_values = linspace(min_temp, max_temp, temp_div);
    
    img_count = 0;
    
    for i=1:totalSize
        
        istr = sprintf('%d', fuel_index(i));
        
        % Set the fuel type
        cmd = ['setAttr fire_volume_shader.fuel_type ' istr];
        sendToMaya(sendMayaScript, port, cmd);
        
        color_temp_table = zeros(temp_div, 4);
        
        for j=1:temp_div;
            starttic = tic;
            
            color_temp_table(j, 1) = temp_values(j);
            
            temperature_str = num2str(temp_values(j));
            
            % Set the temperature
            cmd = ['setAttr fire_volume_shader.temperature_offset ' temperature_str];
            sendToMaya(sendMayaScript, port, cmd);
            
            % Set the folder and name of the render image
            cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
            out_img_name = [fuel_name{i} '-' temperature_str 'K-' scene_name];
            cmd = [cmd scene_name '/' output_img_folder_name out_img_name '\"'];
            sendToMaya(sendMayaScript, port, cmd);
            
            % Render the image
            cmd = 'Mayatomr -render -renderVerbosity 2';
            sendToMaya(sendMayaScript, port, cmd, 1, mrLogPath);
            
            % Read the image
            c_img = imread([output_img_folder out_img_name '.tif']);
            
            [centre_x, centre_y, ~] = size(c_img);
            
            centre_x = round(centre_x / 2);
            centre_y = round(centre_y / 2);
            
            color_temp_table(j, 2:4) = c_img(centre_x, centre_y, 1:3);
            
            % Estimate the remaining time
            img_count = img_count + 1;
            
            c_time = toc(starttic);
            total_time = total_time + c_time;
            mean_time = total_time / (img_count);
            remaining_time = ((totalSize * temp_div - (img_count)) * mean_time) / 86400;
            
            disp(['Image ' num2str(img_count) '/' num2str(totalSize * temp_div) ...
                ' rendered, remaining time ' datestr(remaining_time, 'HH:MM:SS.FFF')]);
            
        end
        
        save([output_img_folder fuel_name{i} '.mat'], 'color_temp_table');
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