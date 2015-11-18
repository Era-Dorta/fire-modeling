function [ error ] = heat_map_fitness( heat_map_v, xyz, whd, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
    port, mrLogPath, goal_img)
% Heat map fitness function
output_img_folder = [scene_img_folder output_img_folder_name];
%% Make temp dir for the render image
[~, tmpdir] = system(['mktemp -d ' output_img_folder 'dirXXXXXX']);
[~,tmpdirName,~] = fileparts(tmpdir);
% Remove end on line characters
tmpdirName = regexprep(tmpdirName,'\r\n|\n|\r','');

%% Save the heat_map in a file
heat_map_path = [scene_img_folder output_img_folder_name tmpdirName '/heat-map.raw'];
volumetricData = struct('xyz', xyz, 'v', heat_map_v', 'size', whd, ...
    'count', size(xyz,1));
save_raw_file(heat_map_path, volumetricData);

%% Set the heat map file as temperature file
% We need the full path to the file or the rendering will fail
cmd = 'setAttr -type \"string\" fire_volume_shader.temperature_file \"';
cmd = [cmd '$HOME/' heat_map_path(3:end) '\"'];
sendToMaya(sendMayaScript, port, cmd);

%% Set the folder and name of the render image
cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
cmd = [cmd scene_name '/' output_img_folder_name tmpdirName '/fireimage' '\"'];
sendToMaya(sendMayaScript, port, cmd);

%% Render the image
% This command only works on Maya running in batch mode, if running with
% the GUI, use Mayatomr -preview. and then save the image with
% $filename = "Path to save";
% renderWindowSaveImageCallback "renderView" $filename "image";
startTime = tic;
cmd = 'Mayatomr -render -camera \"camera1\" -renderVerbosity 5';
sendToMaya(sendMayaScript, port, cmd, 1, mrLogPath);
fprintf('Image rendered with');

%% Compute the error with respect to the goal image
c_img = imread([output_img_folder tmpdirName '/fireimage.tif']);
c_img = c_img(:,:,1:3); % Transparency is not used, so ignore it

% Evaluate all the error functions, usually only one will be given
num_error_foos = size(error_foo, 2);
error = zeros(1, num_error_foos);
for i=1:num_error_foos
    if(sum(c_img(:)) == 0)
        % If the rendered image is completely black set the error manually
        error(i) = realmax;
    else
        error(i) = sum(feval(error_foo{i}, goal_img, c_img));
    end
end

% Print the rest of the information on the same line
fprintf(' error %.2f, in %.2f seconds.\n', error(1), toc(startTime));

% Delete the temporary files
system(['rm -rf ' tmpdir]);

end
