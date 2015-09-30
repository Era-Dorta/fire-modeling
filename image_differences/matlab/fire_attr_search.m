%% Initialization all

clear all;
close all;

% N.B. If Matlab is started from the GUI and custom paths are used for the
% Maya plugins, Matlab will not read the Maya path variables that were
% defined in the .bashrc file and the render script will fail, a 
% workouround is to redefine them here:
% setenv('MAYA_SCRIPT_PATH', 'scripts path');
% setenv('MI_CUSTOM_SHADER_PATH', ' shaders include path');
% setenv('MI_LIBRARY_PATH', 'shaders path');

max_ite = 10; % Num of maximum iterations
epsilon = 100; % Error tolerance

fire_shader_name = 'fire_volume_shader';
project_path = '~/maya/projects/fire/';
scene_name = 'test56_like39_ray_march_fix';
scene_path = [project_path 'scenes/' scene_name '.ma' ];
output_img_folder = [project_path 'images/' scene_name '/'];
goal_img_path = [project_path 'images/' scene_name '/test56_like39_ray_march_fix.001.Le.tif'];
goal_img = imread(goal_img_path);

% Render script is located on the same folder as this file
[pathToRenderScript,~,~] = fileparts(mfilename('fullpath'));
pathToRenderScript = [pathToRenderScript '/render-diff.sh'];

% <densityScale> <densityOffset> <temperatureScale> <temperatureOffset> <intensity> <transparency>
fire_attr = zeros(6, 1);

disp(['Initializing, scene name ' scene_name ', epsilon ' num2str(epsilon) ]);

%% Generate random values for the parameters first step
% densityScale
min = 1;
max = 100;
fire_attr(1) = min + (max - min) * rand(1);

% densityOffset
min = 0;
max = 100;
fire_attr(2) = min + (max - min) * rand(1);

% temperatureScale
min = 1;
max = 1000000;
fire_attr(3) = min + (max - min) * rand(1);

% temperatureOffset
min = 1;
max = 10000;
fire_attr(4) = min + (max - min) * rand(1);

% intensity
min = 1;
max = 100;
fire_attr(5) = min + (max - min) * rand(1);

% transparency
min = 1;
max = 100;
fire_attr(6) = min + (max - min) * rand(1);

%% Render one image with this parameters

cmdStr = [pathToRenderScript ' ' scene_path ' 0'];
for i=1:size(fire_attr)
    cmdStr = [cmdStr ' ' num2str(fire_attr(i))];
end

tTotalStart = tic;
if(system(cmdStr) ~= 0)
    disp(['Render error, check the logs in ' output_img_folder '*.log']);
    return;
end
disp(['Rendered initialization image in ' num2str(toc) ' seconds.']);

%% Compute the error with respect to the goal image
c_img = imread([output_img_folder scene_name '0.tif']);
best_error = sum(MSE(goal_img, c_img));
% Update to 2014 to use the builtin mse
% best_error = immse(goal_img, c_img); % MSE of the two images
best_attr = fire_attr;

%% Main loop auxilary variables initialization
c_error = best_error;
c_ite = 1;
best_ite = 0;

%% Main loop
while (c_ite < max_ite &&  best_error > epsilon)
    tic;
    %##############################################
    % Generate random values for the parameters
    %##############################################
    % densityScale
    min = 1;
    max = 100;
    fire_attr(1) = min + (max - min) * rand(1);
    
    % densityOffset
    min = 0;
    max = 100;
    fire_attr(2) = min + (max - min) * rand(1);
    
    % temperatureScale
    min = 1;
    max = 1000000;
    fire_attr(3) = min + (max - min) * rand(1);
    
    % temperatureOffset
    min = 1;
    max = 10000;
    fire_attr(4) = min + (max - min) * rand(1);
    
    % intensity
    min = 1;
    max = 100;
    fire_attr(5) = min + (max - min) * rand(1);
    
    % transparency
    min = 1;
    max = 100;
    fire_attr(6) = min + (max - min) * rand(1);
       
    %##############################################
    % Render new image
    %##############################################
    
    cmdStr = [pathToRenderScript ' ' scene_path ' ' num2str(c_ite)];
    for i=1:size(fire_attr)
        cmdStr = [cmdStr ' ' num2str(fire_attr(i))];
    end
    
    if(system(cmdStr) ~= 0)
       disp(['Render error, check the logs in ' output_img_folder '*.log']);
       return;
    end
       
    % Compute error
    c_img = imread([output_img_folder scene_name num2str(c_ite) '.tif']);
    c_error = sum(MSE(goal_img, c_img));
    
    % Update if we are closer to the image
    if(c_error < best_error)
        best_error = c_error;
        best_attr = fire_attr;
        best_ite = c_ite;
    end
    
    disp(['Iteration ' num2str(c_ite) ' of max ' num2str(max_ite)  ...
        ', current error ' num2str(c_error) ', best error '  ...
        num2str(best_error) ', render time ' num2str(toc) ' seconds.' ]);
    c_ite = c_ite + 1;
end

save('fire_attr_search.txt', 'best_error', 'best_attr', '-ascii');
disp(['Best image is number ' num2str(best_ite) ', attributes writen in '...
    'fire_attr_search.txt, took ' num2str(toc(tTotalStart)/60) ...
    ' minutes in total.']);