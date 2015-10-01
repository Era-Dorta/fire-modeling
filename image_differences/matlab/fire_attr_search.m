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
scene_img_folder = [project_path 'images/' scene_name '/'];
goal_img_path = [scene_img_folder 'test56_like39_ray_march_fix.001.Le.tif'];
goal_img = imread(goal_img_path);

try
    %% Avoid data overwrites by always creating a new folder
    % Find the last folder
    dir_num = 0;
    while(exist([scene_img_folder 'attr_search_' num2str(dir_num)], 'dir') == 7)
        dir_num = dir_num + 1;
    end
    
    % Create a new folder to store the data
    output_img_folder = [scene_img_folder 'attr_search_' num2str(dir_num) '/'];
    output_data_file = [output_img_folder 'fire_attributes.txt'];
    summary_file = [output_img_folder 'summary_file.txt'];
    disp(['Creating new output folder in ' output_img_folder]);
    system(['mkdir ' output_img_folder]);
    
    %% Genetic call
    do_genetic = true;
    if(do_genetic)
        % Wrap the fitness function into an anonymous one with only the fire
        % shader parameters as arguments
        fitness_foo = @(x)fire_shader_fitness(x, scene_name, scene_path, ...
            scene_img_folder, goal_img);
        
        tic;
        % Call the genetic algoritihm optimization
        fire_attr = ga(fitness_foo, 6);
        disp(['Optimization done in ' num2str(toc) ' seconds.']);
        disp(['Final parameters are ' fire_attr]);
        
        % Transpose the ouput to get a column vector
        fire_attr = fire_attr';
        
        disp(['Saving optimization result in ' output_data_file]);
        save(output_data_file, 'fire_attr', '-ascii');
        
        % If running in batch mode, exit matlab
        if(isBatchMode())
            system(['mv matlab.log ' output_img_folder 'matlab.log']);
            exit;
        else
            return;
        end
    end
    
    %% Script initialization
    % Render script is located on the same folder as this file
    [pathToRenderScript,~,~] = fileparts(mfilename('fullpath'));
    pathToRenderScript = [pathToRenderScript '/render-diff.sh'];
    
    baseCmdStr = [pathToRenderScript ' ' scene_path ' attr_search_' num2str(dir_num) ' '];
    
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
    
    c_ite = 1;
    cmdStr = [baseCmdStr num2str(c_ite)];
    for i=1:size(fire_attr)
        cmdStr = [cmdStr ' ' num2str(fire_attr(i))];
    end
    
    tTotalStart = tic;
    tic;
    if(system(cmdStr) ~= 0)
        disp(['Render error, check the logs in ' output_img_folder '*.log']);
        return;
    end
    
    %% Compute the error with respect to the goal image
    c_img = imread([output_img_folder scene_name num2str(c_ite) '.tif']);
    best_error = sum(MSE(goal_img, c_img));
    % Update to 2014 to use the builtin mse
    % best_error = immse(goal_img, c_img); % MSE of the two images
    best_attr = fire_attr;
    
    %% Main loop auxilary variables initialization
    c_error = best_error;
    best_ite = c_ite;
    
    disp(['Iteration ' num2str(c_ite) ' of max ' num2str(max_ite)  ...
        ', current error ' num2str(c_error) ', best error '  ...
        num2str(best_error) ', render time ' num2str(toc) ' seconds.' ]);
    
    c_ite = 2;
    
    %% Main loop
    while (c_ite <= max_ite &&  best_error > epsilon)
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
        
        cmdStr = [baseCmdStr num2str(c_ite)];
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
    
    if(~exist(output_data_file, 'file') && ~exist(summary_file, 'file'))
        % Save attributes file
        save(output_data_file, 'best_attr', '-ascii');
        
        % Save summary file
        fileId = fopen(summary_file, 'w');
        fprintf(fileId, 'Best image number is %d\n', best_ite);
        fprintf(fileId, 'Image error is %f\n', best_error);
        fprintf(fileId, 'Epsilon %f\n', epsilon);
        fprintf(fileId, 'Max iterations is %d\n', max_ite);
        fprintf(fileId, 'Job took %f seconds\n', toc(tTotalStart));
        fprintf(fileId, 'Density scale %f\n', best_attr(1));
        fprintf(fileId, 'Density offset %f\n', best_attr(2));
        fprintf(fileId, 'Temperature scale %f\n', best_attr(3));
        fprintf(fileId, 'Temperature offset %f\n', best_attr(4));
        fprintf(fileId, 'Intensity %f\n', best_attr(5));
        fprintf(fileId, 'Opacity %f\n', best_attr(6));
        
        % Display final result to user
        disp(['Best image is number ' num2str(best_ite) ', attributes writen in '...
            output_data_file ]);
        disp(['    took ' num2str(toc(tTotalStart)/60) ' minutes in total.']);
        
        % If running in batch mode, exit matlab
        if(isBatchMode())
            system(['mv matlab.log ' output_img_folder 'matlab.log']);
            exit;
        end
    else
        disp(['Cannot overwrite file ' output_data_file ', save into new ']);
        disp (['    location manually with save("<new file path>", "best_error", "best_attr", "-ascii");']);
    end
    
catch ME
    if(isBatchMode())
        disp(getReport(ME));
        if(exist('matlab.log', 'file'))
            system(['mv matlab.log ' output_img_folder 'matlab.log']);
        end
        exit;
    else
        rethrow(ME);
    end
end
