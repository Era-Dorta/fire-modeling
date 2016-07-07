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
scene_name = 'test102_maya_data';
scene_img_folder = fullfile(project_path, 'images', scene_name);
mask_path = fullfile(scene_img_folder, 'flame-30-mask1-cttable.png');

temp_div = 25;
min_temp = 1000;
max_temp = 2500;

%% Avoid data overwrites by always creating a new folder
try
    if(nargin > 2)
        error('Too many input arguments.');
    end
    
    if(isBatchMode() && nargin <= 1)
        error('Logfile name is required when running in batch mode');
    end
    
    % Find the last folder
    dir_num = 0;
    while(exist(fullfile(scene_img_folder, ['ct_table' num2str(dir_num)]), ...
            'dir') == 7)
        dir_num = dir_num + 1;
    end
    
    % Create a new folder to store the data
    output_img_folder = fullfile(scene_img_folder, ['ct_table' num2str(dir_num) '/']);
    output_img_folder_name = ['ct_table' num2str(dir_num)];
    output_ct_folder = fullfile(fileparts(mfilename('fullpath')), 'data');
    
    %% Read mask data
    mask = imread(mask_path);
    mask = logical(mask);
    
    %% Ouput folder
    disp(['Creating new output folder ' output_img_folder]);
    mkdir(scene_img_folder, output_img_folder_name);
    
    %% Maya initialization
    
    if isBatchMode()
        empty_maya_log_files(logfile, port);
    end
    
    % Render script is located in the same maya_comm folder
    [currentFolder,~,~] = fileparts(mfilename('fullpath'));
    sendMayaScript = fullfile(currentFolder, 'maya_comm', 'sendMaya.rb');
    
    maya_send = @(cmd, isRender) sendToMaya( sendMayaScript, ...
        port, cmd, isRender);
    
    if isBatchMode()
        empty_maya_log_files(logfile, port);
    end
    
    maya_common_initialization({maya_send}, port, scene_name, 0, 1, true);
    
    % Set the scale to 0, so that we can control the temperature with the
    % offset regardless of the initial values in the raw file
    cmd = 'setAttr fire_volume_shader.temperature_scale 0';
    maya_send(cmd, 0);
    
    %% Render each image
    total_time = 0;
    
    % Fuel names and fuel indices in Maya
    fuel_name = get_fuel_name();
    totalSize = numel(fuel_name);
    fuel_index =0:totalSize-1;
    
    temp_values = linspace(min_temp, max_temp, temp_div);
    
    img_count = 0;
    
    % Check that the output folder is empty before rendering, better tell
    % the user as soon as possible
    for i=1:totalSize
        ct_file_path = fullfile(output_ct_folder, ['CT-' fuel_name{i} '.mat']);
        if(exist(ct_file_path, 'file'))
            error(['Data file ' ct_file_path '.mat exits output folder ' ...
                'must be empty' ]);
        end
    end
    
    % Render for all fuels and for all temperature samples
    for i=1:totalSize
        
        istr = sprintf('%d', fuel_index(i));
        
        % Set the fuel type
        cmd = ['setAttr fire_volume_shader.fuel_type ' istr];
        maya_send(cmd, 0);
        
        color_temp_table = zeros(temp_div, 4);
        
        for j=1:temp_div;
            starttic = tic;
            
            color_temp_table(j, 1) = temp_values(j);
            
            temperature_str = num2str(temp_values(j));
            
            % Set the temperature
            cmd = ['setAttr fire_volume_shader.temperature_offset ' temperature_str];
            maya_send(cmd, 0);
            
            % Set the folder and name of the render image
            cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
            out_img_name = [fuel_name{i} '-' temperature_str 'K-' scene_name];
            cmd = [cmd fullfile(scene_name, output_img_folder_name, out_img_name ) '\"'];
            maya_send(cmd, 0);
            
            % Render the image
            cmd = 'Mayatomr -render -renderVerbosity 2';
            maya_send(cmd, 1);
            
            % Read the image
            c_img = imread(fullfile(output_img_folder, [out_img_name '.tif']));
            
            for k=1:3
                img = c_img(:,:,k);
                color_temp_table(j, k+1) = mean(img(mask));
            end
            
            % Estimate the remaining time
            img_count = img_count + 1;
            
            c_time = toc(starttic);
            total_time = total_time + c_time;
            mean_time = total_time / (img_count);
            remaining_time = ((totalSize * temp_div - (img_count)) * mean_time) / 86400;
            
            disp(['Image ' num2str(img_count) '/' num2str(totalSize * temp_div) ...
                ' rendered, remaining time ' datestr(remaining_time, 'HH:MM:SS.FFF')]);
        end
        ct_file_path = fullfile(output_ct_folder, ['CT-' fuel_name{i} '.mat']);
        save(ct_file_path, 'color_temp_table', '-ascii', '-double');
    end
    
    %% Resource clean up after execution
    
    % If running in batch mode, exit matlab
    if(isBatchMode())
        move_file( logfile, fullfile(output_img_folder, 'matlab.log') );
        copy_maya_log_files(logfile, output_img_folder, port);
        exit;
    else
        return;
    end
catch ME
    if(isBatchMode())
        disp(getReport(ME));
        if(exist('logfile', 'var') && exist('output_img_folder', 'var'))
            move_file( logfile, fullfile(output_img_folder, 'matlab.log') );
            if(exist('port', 'var'))
                copy_maya_log_files(logfile, output_img_folder, port);
            end
        end
        exit;
    else
        rethrow(ME);
    end
end
end