function fire_attr_search2(solver, logfile)
%FIRE_ATTR_SEARCH2 Fire render parameters estimate from image
% Solver should be one of the following
% 'ga' -> Genetic Algorithms
% 'sa' -> Simulated Annealing
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

max_ite = 1000; % Num of maximum iterations
% epsilon = 100; % Error tolerance, using Matlab default's at the moment
time_limit = 24 * 60 * 60; % In seconds

% Lower bounds, mostly due to avoiding division by zero or setting
% the colour to zero directly
LB = [1, 1, 1, 1];

% Upper bounds, empirically set given the equations and our data
UB = [10000, 1000, 100, 100];

% To modigy parameters specific to each solver go to the
% do_<solver>_solve() function

project_path = '~/maya/projects/fire/';
scene_name = 'test78_like_72_4x4x4_raw';
scene_img_folder = [project_path 'images/' scene_name '/'];
goal_img_path = [scene_img_folder 'goalimage.tif'];

% Error function to be used for the fitness function, it must accept two
% images and return an error value
error_foo = {@histogramErrorOpti};
errorFooCloseObj = onCleanup(@() clear(func2str(error_foo{:})));

%% Avoid data overwrites by always creating a new folder
try
    if(nargin == 0)
        error('Not enough input arguments.');
    end
    
    if(isBatchMode() && nargin < 2)
        error('Logfile name is required when running in batch mode');
    end
    
    % Find the last folder
    dir_num = 0;
    while(exist([scene_img_folder 'attr_search_' num2str(dir_num)], 'dir') == 7)
        dir_num = dir_num + 1;
    end
    
    % Create a new folder to store the data
    output_img_folder = [scene_img_folder 'attr_search_' num2str(dir_num) '/'];
    output_img_folder_name = ['attr_search_' num2str(dir_num) '/'];
    summary_file = [output_img_folder 'summary_file'];
    % It will be saved as fig and tiff
    error_figure = [output_img_folder 'error_function'];
    paths_str = struct('summary',  summary_file, 'errorfig', error_figure, ...
        'output_folder',  output_img_folder);
    mrLogPath = [scene_img_folder output_img_folder_name 'mentalray.log'];
    
    % Read goal image
    goal_img = imread(goal_img_path);
    goal_img = goal_img(:,:,1:3); % Transparency is not used, so ignore it
    
    %% SendMaya script initialization
    % Render script is located in the same maya_comm folder
    [currentFolder,~,~] = fileparts(mfilename('fullpath'));
    sendMayaScript = [currentFolder '/maya_comm/sendMaya.rb'];
    
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
    cmd = ['file -open \"scenes/' scene_name '.ma\"'];
    sendToMaya(sendMayaScript, port, cmd);
    
    % Force a frame update, as batch rendering later does not do it, this
    % will fix any file name errors due to using the same scene on
    % different computers
    cmd = '\$ctime = \`currentTime -query\`; currentTime 1; currentTime \$ctime';
    sendToMaya(sendMayaScript, port, cmd);
    
    %% Ouput folder
    disp(['Creating new output folder ' output_img_folder]);
    system(['mkdir ' output_img_folder]);
    
    %% Fitness function definition
    
    % Wrap the fitness function into an anonymous function whose only
    % parameter is the heat map
    fitness_foo = memoize(@(x)render_attr_fitness(x, error_foo, ...
        scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
        port, mrLogPath, goal_img));
    
    %% Summary extra data
    summary_data = struct('GoalImage', goal_img_path, 'MayaScene', ...
        [project_path 'scenes/' scene_name '.ma'], 'ErrorFc', ...
        func2str(error_foo{:}));
    
    %% Solver call
    disp('Launching optimization algorithm');
    switch solver
        case 'ga'
            %% Options for the ga
            % Get an empty gaoptions structure
            options = gaoptimset;
            options.PopulationSize = 30;
            %options.Generations = max(fix(max_ite / options.PopulationSize), 1);
            options.TimeLimit = time_limit;
            options.Display = 'iter'; % Give some output on each iteration
            options.StallGenLimit = 10;
            
            % Function executed on each iteration, there is a PlotFcns too, but it
            % creates a figure outside of our control and it makes the plotting and
            % saving too dificult
            plotf = @(options,state,flag)gaplotbestcustom(options, state, flag, paths_str.errorfig);
            
            % Matlab is using cputime to measure time limits in GA and Simulated
            % Annealing solvers, which just doesn't work with multiple cores and
            % multithreading even if the value is scaled with the number of cores.
            % Add a custom function to do the time limit check
            startTime = tic;
            timef = @(options, state, flag)ga_time_limit( options, state, flag, startTime);
            
            options.OutputFcns = {plotf, timef};
            
            % Our only constrains are upper and lower bounds
            A = [];
            b = [];
            Aeq = [];
            beq = [];
            nonlcon = [];
            disp(['Population size ' num2str(options.PopulationSize) ', number of '...
                'variables 4']);
            
            %% Call the genetic algorithm optimization
            
            [render_attr, best_error, exitflag] = ga(fitness_foo, 4, ...
                A, b, Aeq, beq, LB, UB, nonlcon, options);
            
            totalTime = toc(startTime);
            disp(['Optimization total time ' num2str(totalTime)]);
            
            summary_data.OptimizationMethod = 'Genetic Algorithms';
            summary_data.ImageError = best_error;
            summary_data.NumVariables = 4;
            summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
            summary_data.LowerBounds = LB;
            summary_data.UpperBounds = UB;
            
            save_summary_file(paths_str.summary, summary_data, options);
        case 'sa'
            %
        case 'grad'
            %
        otherwise
            solver_names = '[''ga'', ''sa'', ''grad'']';
            error(['Invalid solver, choose one of ' solver_names ]);
    end
    
    %% Save the best attr file
    render_attr_path = [output_img_folder 'render_attr.mat'];
    disp(['Final render attr saved in ' render_attr_path]);
    save(render_attr_path, 'render_attr');
    
    %%  Render the best image again
    % Set the render attributes
    cmd = ['setAllFireAttributes(\"fire_volume_shader\", ' ...
        '0.010, 0,' num2str(render_attr(1)) ', ' num2str(render_attr(2)) ', ' ...
        num2str(render_attr(3)) ', ' num2str(render_attr(4)) ')'];
    sendToMaya(sendMayaScript, port, cmd);
    
    % Set the folder and name of the render image
    cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
    cmd = [cmd scene_name '/' output_img_folder_name 'optimized' '\"'];
    sendToMaya(sendMayaScript, port, cmd);
    
    disp(['Rendering final image in ' output_img_folder 'optimized.tif' ]);
    
    % Render the image
    tic;
    cmd = 'Mayatomr -render -camera \"camera1\" -renderVerbosity 5';
    sendToMaya(sendMayaScript, port, cmd, 1, mrLogPath);
    disp(['Image rendered in ' num2str(toc) ]);
    
    %% Resource clean up after execution
    
    % If running in batch mode, exit matlab
    if(isBatchMode())
        move_file( logfile, [output_img_folder 'matlab.log'] );
        exit;
    else
        % If GUI running, show the computed final image
        figure;
        optimized_img = imread([output_img_folder 'optimized.tif']);
        imshow(optimized_img(:,:,1:3));
        return;
    end
catch ME
    if(isBatchMode())
        disp(getReport(ME));
        if(exist('logfile', 'var') && exist('output_img_folder', 'var'))
            move_file( logfile, [output_img_folder 'matlab.log'] );
        end
        exit;
    else
        rethrow(ME);
    end
end
end