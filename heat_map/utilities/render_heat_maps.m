function render_heat_maps( heat_map_v, xyz, whd, scene_name, scene_img_folder, ...
    output_img_folder_name, output_folder, sendMayaScript, port, mrLogPath)
%RENDER_HEAT_MAPS Renders heat maps in a folder
%    RENDER_HEAT_MAPS( HEAT_MAP_V, XYZ, WHD, SCENE_NAME, SCENE_IMG_FOLDER, ...
%     OUTPUT_IMG_FOLDER_NAME, SENDMAYASCRIPT, PORT, MRLOGPATH)

output_img_folder = [scene_img_folder output_img_folder_name];

% Create directory for the render images
system(['mkdir ' output_img_folder output_folder]);

all_population_img = [];
c_row_img = [];
num_column = 0;

for pop=1:size(heat_map_v, 1)
    
    popstr = num2str(pop);
    
    %% Save the heat_map in a file
    heat_map_path = [scene_img_folder output_img_folder_name output_folder ...
        '/heat-map' popstr '.raw'];
    volumetricData = struct('xyz', xyz, 'v', heat_map_v(pop, :)', 'size', whd, ...
        'count', size(xyz,1));
    save_raw_file(heat_map_path, volumetricData);
    
    %% Set the heat map file as temperature file
    % Either set the full path or set the file relative maya path for
    % temperature_file_first and force frame update to run
    cmd = 'setAttr -type \"string\" fire_volume_shader.temperature_file \"';
    cmd = [cmd '$HOME/' heat_map_path(3:end) '\"'];
    sendToMaya(sendMayaScript, port, cmd);
    
    %% Set the folder and name of the render image
    cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
    cmd = [cmd scene_name '/' output_img_folder_name output_folder '/fireimage' ...
        popstr '\"'];
    sendToMaya(sendMayaScript, port, cmd);
    
    %% Render the image
    % This command only works on Maya running in batch mode, if running with
    % the GUI, use Mayatomr -preview. and then save the image with
    % $filename = "Path to save";
    % renderWindowSaveImageCallback "renderView" $filename "image";
    cmd = 'Mayatomr -render -camera \"camera1\" -renderVerbosity 5';
    sendToMaya(sendMayaScript, port, cmd, 1, mrLogPath);
    
    c_img = imread([scene_img_folder output_img_folder_name output_folder ...
        '/fireimage' popstr '.tif']);
    c_img = c_img(:,:,1:3);
    
    if ~exist('max_column','var')
        % Assuming all result images have the same size and that we want to
        % build of mosaic of width 1920 pixels
        max_column = max(floor(1920 / size(c_img, 2)), 1);
    end
    
    c_row_img = [c_row_img, c_img];
    num_column = num_column + 1;
    
    if(num_column >= max_column)
        all_population_img = [all_population_img; c_row_img];
        c_row_img = [];
        num_column = 0;
    end
end
% Check if last row was not completed
if(~isempty(c_row_img))
    % Create a padding with black squares
    c_size = size(c_row_img);
    padding = zeros(c_size(1), size(all_population_img, 2) - c_size(2), ...
        c_size(3));
    padding(1:10:end, :,:) = 255;
    padding(:,1:10:end,:) = 255;
    
    all_population_img = [all_population_img; c_row_img, padding];
end
imwrite(all_population_img, ...
    [scene_img_folder output_img_folder_name output_folder '/AllPopulation.tif']);
end
