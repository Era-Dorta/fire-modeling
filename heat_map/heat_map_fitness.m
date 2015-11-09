function [ error ] = heat_map_fitness( heat_map, scene_name, goal_img )
%% Make temp dir for the render image
[~, tmpdir] = system(['mktemp -d ' output_img_folder 'dirXXXXXX']);
[~,tmpdirName,~] = fileparts(tmpdir);
% Remove end on line characters
tmpdirName = regexprep(tmpdirName,'\r\n|\n|\r','');

%% Set the folder and name of the render image
cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
cmd = [cmd scene_name '/' output_img_folder_name tmpdirName '/fireimage' '\"'];
if(~sendToMaya(cmd, sendMayaScript))
    disp('Could not send Maya command');
    return;
end

%% Render the image
tic;
cmd = 'Mayatomr -render -camera \"camera1\" -renderVerbosity 5 -logFile';
if(~sendToMaya(cmd, sendMayaScript, 1))
    renderImgPath = [scene_img_folder output_img_folder_name tmpdirName '/'];
    disp(['Render error, check the logs in ' renderImgPath '*.log']);
    closeMayaAndMoveMRLog(renderImgPath);
    return;
end
fprintf('Image rendered with ');

%% Compute the error with respect to the goal image
c_img = imread([output_img_folder tmpdirName 'fireimage.tif']);
c_img = c_img(:,:,1:3); % Transparency is not used, so ignore it

% If the rendered image is completely black set the error manually
if(sum(c_img(:)) == 0)
    error = realmax;
else
    error = sum(MSE(goal_img, c_img));
end

% Print the rest of the information on the same line
fprintf(' error %.2f, in %.2f seconds.\n',error, toc);

% Delete the temporary files
system(['rm -rf ' tmpdir]);

end
