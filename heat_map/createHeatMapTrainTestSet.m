function createHeatMapTrainTestSet(totalSize, save_mat, logfile)
%CREATEHEATMAPTRAINTESTSET Create heatmap  train and test data
%   CREATEHEATMAPTRAINTESTSET(TOTAL_SIZE = 1000, LOGFILE) If running in
%   batch mode a LOGFILE is required

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

LB = 300; % Lower bounds, no less than 300K -> 27C
UB = 10000; % Upper bounds, no more than 10000K -> 9727C

meanhm = 0;
sigmahm = 500;

project_path = '~/maya/projects/fire/';
scene_name = 'test78_like_72_4x4x4_raw';
raw_file_path = 'data/heat_maps/gaussian4x4x4.raw';
scene_img_folder = [project_path 'images/' scene_name '/'];

%% Avoid data overwrites by always creating a new folder
try
    if(nargin > 4)
        error('Too many input arguments.');
    end
    
    if(isBatchMode() && nargin < 3)
        error('Logfile name is required when running in batch mode');
    end
    
    if(nargin < 2)
        save_mat = false;
        if(nargin < 1)
            totalSize = 1000;
        end
    end
    
    if(ischar(totalSize))
        totalSize = str2double(totalSize);
    end
    
    if(totalSize <= 0)
        error('totalSize has to be a positive number.');
    end
    
    if(~islogical(save_mat))
        error(['Second argument must be of type "logical", "' class(save_mat) '" found.']);
    end
    
    % Find the last folder
    dir_num = 0;
    while(exist([scene_img_folder 'render_approx_data' num2str(dir_num)], 'dir') == 7)
        dir_num = dir_num + 1;
    end
    
    % Create a new folder to store the data
    output_img_folder = [scene_img_folder 'render_approx_data' num2str(dir_num) '/'];
    output_img_folder_name = ['render_approx_data' num2str(dir_num) '/'];
    summary_file = [output_img_folder 'summary_file'];
    mrLogPath = [scene_img_folder output_img_folder_name 'mentalray.log'];
    
    %% SendMaya script initialization
    % Render script is located in the same maya_comm folder
    [currentFolder,~,~] = fileparts(mfilename('fullpath'));
    sendMayaScript = [currentFolder '/maya_comm/sendMaya.rb'];
    
    %% Volumetric data initialization
    init_heat_map = read_raw_file([project_path raw_file_path]);
    
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
    % the cleanup function is more robust (Ctrl-c, ...) than the try-catch
    mayaCloseObj = onCleanup(@() closeMaya(sendMayaScript, port));
    
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
    mkdir(scene_img_folder, output_img_folder_name);
    
    %% Render each image
    c_heat_map = init_heat_map;
    heat_maps = zeros(totalSize, c_heat_map.count);
    
    if(save_mat)
        images = cell(totalSize, 1);
        % Create 256 bins, image can be 0..255
        edges = linspace(0, 255, 256);
        histocounts = cell(totalSize, 1);
    end
    
    total_time = 0;
    render_time = tic;
    for i=1:totalSize
        starttic = tic;
        
        istr = sprintf('%04d', i);
        
        c_heat_map.v = init_heat_map.v + random('norm', meanhm, sigmahm, ...
            [c_heat_map.count, 1]);
        c_heat_map.v = min(max(c_heat_map.v, LB), UB);
        
        heat_map_path = [output_img_folder 'heat-map' istr '.raw'];
        save_raw_file(heat_map_path, c_heat_map);
        
        % Set the heat map file as temperature file
        % Either set the full path or set the file relative maya path for
        % temperature_file_first and force frame update to run
        cmd = 'setAttr -type \"string\" fire_volume_shader.temperature_file \"';
        cmd = [cmd '$HOME/' heat_map_path(3:end) '\"'];
        sendToMaya(sendMayaScript, port, cmd);
        
        % Set the folder and name of the render image
        cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
        img_path = [scene_name '/' output_img_folder_name istr];
        cmd = [cmd img_path '\"'];
        sendToMaya(sendMayaScript, port, cmd);
        
        % Render the image
        cmd = 'Mayatomr -render -renderVerbosity 2';
        sendToMaya(sendMayaScript, port, cmd, 1, mrLogPath);
        
        if(save_mat)
            heat_maps(i,:) = c_heat_map.v';
            images{i} = imread([output_img_folder istr '.tif']);
            images{i} = images{i}(:,:, 1:3); % Transparency is not used, so ignore it
            
            c_histo(1, :) = histcounts( images{i}(:, :, 1), edges);
            c_histo(2, :) = histcounts( images{i}(:, :, 2), edges);
            c_histo(3, :) = histcounts( images{i}(:, :, 3), edges);
            
            histocounts{i} = c_histo;
        end
        
        % Estimate the remaining time
        c_time = toc(starttic);
        total_time = total_time + c_time;
        mean_time = total_time / i;
        remaining_time = ((totalSize - i) * mean_time) / 86400;
        
        disp(['Image ' num2str(i) '/' num2str(totalSize) ' rendered, remaining time ' ...
            datestr(remaining_time, 'HH:MM:SS.FFF')]);
    end
    
    render_time = toc(render_time);
    
    %% Save variables and summary data
    summary_data = struct('MayaScene', [project_path 'scenes/' scene_name '.ma'], ...
        'project_path',  project_path , 'scene_name'  ,scene_name , ...
        'raw_file_path' , raw_file_path, 'totalSize', totalSize, 'LB', LB, ...
        'UB', UB, 'renderTime', render_time, 'OptimizationMethod', 'Train Test Generation');
    
    save_summary_file(summary_file, summary_data, struct('ExtraOptions', 'None'));
    
    if(save_mat)
        bin_range = 2:size(histocounts{1}, 2);
        save([output_img_folder 'data.mat'], 'heat_maps', 'images', ...
            'init_heat_map', 'LB', 'UB', 'histocounts', 'edges', 'bin_range');
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