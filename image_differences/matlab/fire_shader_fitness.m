function [ error ] = fire_shader_fitness( fire_attr, scene_name, scene_path, ...
    scene_img_folder, goal_img)

[~, tmpdir] = system(['mktemp -d ' scene_img_folder 'dirXXXXXX']);
[~,tmpdirName,~] = fileparts(tmpdir);
% Remove end on line characters
tmpdirName = regexprep(tmpdirName,'\r\n|\n|\r','');

output_img_folder = [scene_img_folder tmpdirName '/'];

% Render script is located on the same folder as this file
[pathToRenderScript,~,~] = fileparts(mfilename('fullpath'));
pathToRenderScript = [pathToRenderScript '/render-diff.sh'];

cmdStr = [pathToRenderScript ' ' scene_path ' ' tmpdirName ' 0'];

%% Render one image with this parameters
for i=1:size(fire_attr, 2)
    cmdStr = [cmdStr ' ' num2str(fire_attr(i))];
end

tic;
if(system(cmdStr) ~= 0)
    disp(['Render error, check the logs in ' output_img_folder '*.log']);
    error = realmax;
    return;
end
fprintf('    Image rendered with params %.2f %.2f %.2f %.2f %.2f %.2f in %.2f seconds.\n',...
    fire_attr(1), fire_attr(2),     fire_attr(3), fire_attr(4), fire_attr(5), fire_attr(6), toc);

%% Compute the error with respect to the goal image
c_img = imread([output_img_folder scene_name '0.tif']);
error = sum(MSE(goal_img, c_img));

% Delete the temporary files
system(['rm -rf ' tmpdir]);
end

