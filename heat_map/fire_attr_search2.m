function fire_attr_search2(solver, goal_img_path, goal_mask_img_path, ...
    mask_img_path, ports, logfile)
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

num_variables = 5;

% Lower bounds, mostly due to avoiding division by zero or setting
% the colour to zero directly
LB = [0, 0, 1, -1, 0];

% Upper bounds, empirically set given the equations and our data
UB = [1000, 1000, 10, 1, 10];

% To modigy parameters specific to each solver go to the
% do_<solver>_solve() function

project_path = '~/maya/projects/fire/';
scene_name = 'test94_gaussian_rotated_two_cams';
scene_img_folder = [project_path 'images/' scene_name '/'];

% Single and multiple goal image path examples

% goal_img_path = {[scene_img_folder 'goalimage1-asym.tif']};
% goal_mask_img_path = {[scene_img_folder 'maskgoalimage1.png']};
% mask_img_path = {[scene_img_folder 'maskrenderimage1.png']};

% goal_img_path = {[scene_img_folder 'goalimage1-asym.tif'], ...
%     [scene_img_folder 'goalimage2-asym.tif']};
% goal_mask_img_path = {[scene_img_folder 'maskgoalimage1.png'], ...
%     [scene_img_folder 'maskgoalimage2.png']};
% mask_img_path = {[scene_img_folder 'maskrenderimage1.png'], ...
%     [scene_img_folder 'maskrenderimage2.png']};

num_goal = numel(goal_img_path);

% Error function used in the fitness function
error_foo = {@histogramErrorOpti};

% List of function with persistent variables that need to be clean up after
% execution
clear_foo_str = {'histogramErrorOpti', ...
    'heat_map_fitness', 'heat_map_fitness_interp',  ...
    'render_attr_fitness', 'histogramEstimate', 'histogramErrorApprox', ...
    'gaxoverpriorhisto', 'gacrossovercombine'};

% Clear all the functions
clearCloseObj = onCleanup(@() clear(clear_foo_str{:}));
if(numel(ports) > 1)
    % If running of parallel, clear the functions in the workers as well
    clearParCloseObj = onCleanup(@() parfevalOnAll(gcp, @clear, 0, ...
        clear_foo_str{:}));
end

%% Avoid data overwrites by always creating a new folder
try
    if(nargin < 3)
        error('Not enough input arguments.');
    end
    
    if(isBatchMode() && nargin < 4)
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
    
    %% Read goal and mask image/s
    % For MSE resize the goal image to match the synthetic image
    if(isequal(error_foo{1}, @MSE))
        resize_goal = true;
    else
        resize_goal = false;
    end
    [ goal_img, goal_mask, img_mask ] = readGoalAndMask( goal_img_path, ...
        mask_img_path, goal_mask_img_path, resize_goal);
    
    %% SendMaya script initialization
    % Render script is located in the same maya_comm folder
    [currentFolder,~,~] = fileparts(mfilename('fullpath'));
    sendMayaScript = [currentFolder '/maya_comm/sendMaya.rb'];
    
    %% Maya initialization
    % Each maya instance usually renders using 4 cores
    numMayas = numel(ports);
    
    for i=1:numMayas
        disp(['Loading scene in Maya:' num2str(ports(i))]);
        % Set project to fire project directory
        cmd = 'setProject \""$HOME"/maya/projects/fire\"';
        sendToMaya(sendMayaScript, ports(i), cmd);
        
        % Open our test scene
        cmd = ['file -open -force \"scenes/' scene_name '.ma\"'];
        sendToMaya(sendMayaScript, ports(i), cmd);
        
        % Force a frame update, as batch rendering later does not do it, this
        % will fix any file name errors due to using the same scene on
        % different computers
        cmd = '\$ctime = \`currentTime -query\`; currentTime 1; currentTime \$ctime';
        sendToMaya(sendMayaScript, ports(i), cmd);
        
        % Deactive all but the first camera if there is more than one goal
        % image
        for j=2:num_goal
            cmd = ['setAttr \"camera' num2str(j) 'Shape.renderable\" 0'];
            sendToMaya(sendMayaScript, ports(i), cmd);
        end
    end
    
    %% Ouput folder
    disp(['Creating new output folder ' output_img_folder]);
    system(['mkdir ' output_img_folder]);
    
    %% Fitness function definition
    
    % Wrap the fitness function into an anonymous function whose only
    % parameter is the heat map
    fitness_foo = @(x)render_attr_fitness_par(x, error_foo, ...
        scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
        ports, mrLogPath, goal_img, goal_mask, img_mask);
    
    %% Summary extra data
    goal_img_summay = strjoin(goal_img_path, ', ');
    
    summary_data = struct('GoalImage', goal_img_summay, 'MayaScene', ...
        [project_path 'scenes/' scene_name '.ma'], 'ErrorFc', ...
        func2str(error_foo{:}), 'NumMaya', numMayas);
    
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
            options.Vectorized = 'on';
            
            % Have at least one elite individual so that we don't loose
            % the best option by a mutation
            options.EliteCount = 1;
            
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
                'variables ' num2str(num_variables)]);
            
            %% Call the genetic algorithm optimization
            
            [render_attr, best_error, exitflag] = ga(fitness_foo, num_variables, ...
                A, b, Aeq, beq, LB, UB, nonlcon, options);
            
            totalTime = toc(startTime);
            disp(['Optimization total time ' num2str(totalTime)]);
            disp(['Optimization result: ' num2str(render_attr)]);
            
            summary_data.OptimizationMethod = 'Genetic Algorithms';
            summary_data.ImageError = best_error;
            summary_data.NumVariables = num_variables;
            summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
            summary_data.LowerBounds = LB;
            summary_data.UpperBounds = UB;
            
            save_summary_file(paths_str.summary, summary_data, options);
        case 'sa'
            %
            error('To be implemented');
        case 'grad'
            error('To be implemented');
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
    cmd = 'setFireAttributesNew(\"fire_volume_shader\"';
    for i=1:num_variables
        cmd = [cmd ', ' num2str(render_attr(i))];
    end
    cmd = [cmd ')'];
    sendToMaya(sendMayaScript, ports(1), cmd);
    
    disp(['Rendering final images in ' output_img_folder 'optimized<d>.tif' ]);
    
    for i=1:num_goal
        istr = num2str(i);
        
        % Active current camera
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 1'];
        sendToMaya(sendMayaScript, ports(1), cmd);
        
        % Set the folder and name of the render image
        cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
        cmd = [cmd scene_name '/' output_img_folder_name 'optimized' ...
            istr '\"'];
        sendToMaya(sendMayaScript, ports(1), cmd);
        
        % Render the image
        tic;
        cmd = 'Mayatomr -verbosity 2 -render -renderVerbosity 2';
        sendToMaya(sendMayaScript, ports(1), cmd, 1, mrLogPath);
        
        % Deactivate the current camera
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 0'];
        sendToMaya(sendMayaScript, ports(1), cmd);
    end
    
    %% Add single view fitness value for multigoal optimization
    if(num_goal > 1)
        L = load([paths_str.summary '.mat']);
        
        c_img = imread([output_img_folder '/optimized1.tif']);
        c_img = c_img(:,:,1:3); % Transparency is not used, so ignore it
        
        L.summary_data.ImageErrorSingleView = sum(feval(error_foo{1},  ...
            goal_img(1), {c_img}, goal_mask(1), img_mask(1)));
        
        summary_data = L.summary_data;
        save([paths_str.summary '.mat'], 'summary_data', '-append');
    end
    
    %% Resource clean up after execution
    
    % If running in batch mode, exit matlab
    if(isBatchMode())
        move_file( logfile, [output_img_folder 'matlab.log'] );
        exit;
    else
        % If GUI running, show the computed final image
        for i=1:num_goal
            istr = num2str(i);
            figure('Name', ['Optimized Camera' istr] );
            optimized_img = imread([output_img_folder 'optimized' istr ...
                '.tif']);
            imshow(optimized_img(:,:,1:3));
        end
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