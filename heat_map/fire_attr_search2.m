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

% temperature_scale, temperature_offset, intensity, transparency, linear_density
num_variables = 5;

% Lower bounds, mostly due to avoiding division by zero or setting
% the colour to zero directly
LB = [0, 0, 0, -1, 0];

% Upper bounds, temperature scaled will be infered from the data, 2000K of
% temperature offset, and default min max vlaues for the rest
UB = [NaN, 2300, 10, 1, 10];

% To modigy parameters specific to each solver go to the
% do_<solver>_solve() function

project_path = '~/maya/projects/fire/';
scene_name = 'test95_gaussian_new';
scene_img_folder = [project_path 'images/' scene_name '/'];
raw_file_path = 'data/heat_maps/gaussian4x4x4new.raw';

% Single and multiple goal image path examples are in
% [~, ~, ~, goal_img_path, goal_mask_img_path, mask_img_path] = ...
%     get_test_paths(scene_name, multi_goal, symmetric);

% Distance function for the histogram error functions, any of the ones in
% the folder error_fnc/distance_fnc
% Common ones: histogram_l1_norm, histogram_intersection,
% chi_square_statistics_fast
dist_foo = @histogram_l1_norm;

% Error function used in the fitness function
% One of: histogramErrorOpti, histogramDErrorOpti, MSE
error_foo = {@histogramErrorOpti};

% Clear all the functions
clearCloseObj = onCleanup(@clear_cache);
if(numel(ports) > 1)
    % If running of parallel, clear the functions in the workers as well
    clearParCloseObj = onCleanup(@() parfevalOnAll(gcp, @clear_cache, 0));
end

%% Avoid data overwrites by always creating a new folder
try
    if(nargin < 3)
        error('Not enough input arguments.');
    end
    
    if(isBatchMode() && nargin < 4)
        error('Logfile name is required when running in batch mode');
    end
    
    if(~iscell(goal_img_path) || ~iscell(mask_img_path) || ~iscell(goal_mask_img_path) )
        error('Image paths must be cells of strings');
    end
    
    num_goal = numel(goal_img_path);
    
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
        'output_folder',  output_img_folder, 'ite_img', [output_img_folder  ...
        'current1-Cam']);
    
    %% Get upper bound estimate for temperature scale
    init_heat_map = read_raw_file([project_path raw_file_path]);
    
    % The temperature should be roughfly in the 1500K range
    UB(1) = 1500 / mean(init_heat_map.v);
    
    % If it fails try with the max temperature
    if isinf(UB(1)) || isnan(UB(1))
        % As this is a corner case, to be safe double the uppper bounds
        UB(1) = (1500 / max(init_heat_map.v)) * 2;
        
        if isinf(UB(1)) || isnan(UB(1))
            error('Temperatue values in init heat map must be positive');
        end
    end
    
    %% Read goal and mask image/s
    % For MSE resize the goal image to match the synthetic image
    ifisequalFncCell(error_foo{1}, {@MSE, @MSEPerceptual})
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
    
    % Each maya instance usually renders using 4 cores
    numMayas = numel(ports);
    maya_send = cell(numMayas, 1);
    
    for i=1:numMayas
        maya_send{i} = @(cmd, isRender) sendToMaya( sendMayaScript, ...
            ports(i), cmd, isRender);
    end
    
    %% Maya initialization
    if isBatchMode()
        empty_maya_log_files(logfile, ports);
    end
    
    for i=1:numMayas
        disp(['Loading scene in Maya:' num2str(ports(i))]);
        % Set project to fire project directory
        cmd = 'setProject \""$HOME"/maya/projects/fire\"';
        maya_send{i}(cmd, 0);
        
        % Open our test scene
        cmd = ['file -open -force \"scenes/' scene_name '.ma\"'];
        maya_send{i}(cmd, 0);
        
        % Force a frame update, as batch rendering later does not do it, this
        % will fix any file name errors due to using the same scene on
        % different computers
        cmd = '\$ctime = \`currentTime -query\`; currentTime 1; currentTime \$ctime';
        maya_send{i}(cmd, 0);
        
        % Deactive all but the first camera if there is more than one goal
        % image
        for j=2:num_goal
            cmd = ['setAttr \"camera' num2str(j) 'Shape.renderable\" 0'];
            maya_send{i}(cmd, 0);
        end
    end
    
    %% Ouput folder
    disp(['Creating new output folder ' output_img_folder]);
    mkdir(scene_img_folder, output_img_folder_name);
    
    %% Summary extra data
    goal_img_summay = strjoin(goal_img_path, ', ');
    
    summary_data = struct('GoalImage', goal_img_summay, 'MayaScene', ...
        [project_path 'scenes/' scene_name '.ma'], 'ErrorFc', ...
        func2str(error_foo{:}), 'DistFnc', func2str(dist_foo), 'NumMaya', ...
        numMayas);
    
    %% Fitness function definition
    
    % Encapsulate the distance function in the error function
    error_foo{1} = @(x) error_foo{1}(goal_img, x, goal_mask, img_mask, ...
        dist_foo);
    
    % Wrap the fitness function into an anonymous function whose only
    % parameter is the heat map
    fitness_foo = @(x)render_attr_fitness_par(x, error_foo, ...
        scene_name, scene_img_folder, output_img_folder_name, maya_send, ...
        num_goal);
    
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
            
            % Plot the rendered image of the best heat map on each iteration
            plothm = @(options,state,flag)gaplotbestgen(options, state, flag, ...
                paths_str.ite_img, paths_str.output_folder, num_goal);
            
            % Matlab is using cputime to measure time limits in GA and Simulated
            % Annealing solvers, which just doesn't work with multiple cores and
            % multithreading even if the value is scaled with the number of cores.
            % Add a custom function to do the time limit check
            startTime = tic;
            timef = @(options, state, flag)ga_time_limit( options, state, flag, startTime);
            
            options.OutputFcns = {plotf, plothm, timef};
            
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
    maya_send{1}(cmd, 0);
    
    disp(['Rendering final images in ' output_img_folder 'optimized-Cam<d>.tif' ]);
    
    for i=1:num_goal
        istr = num2str(i);
        
        % Active current camera
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 1'];
        maya_send{1}(cmd, 0);
        
        % Set the folder and name of the render image
        cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
        cmd = [cmd scene_name '/' output_img_folder_name 'optimized-Cam' ...
            istr '\"'];
        maya_send{1}(cmd, 0);
        
        % Render the image
        tic;
        cmd = 'Mayatomr -verbosity 2 -render -renderVerbosity 2';
        maya_send{1}(cmd, 1);
        
        % Deactivate the current camera
        cmd = ['setAttr \"camera' istr 'Shape.renderable\" 0'];
        maya_send{1}(cmd, 0);
    end
    
    %% Add single view fitness value for multigoal optimization
    if(num_goal > 1)
        L = load([paths_str.summary '.mat']);
        
        c_img = imread([output_img_folder 'optimized-Cam1.tif']);
        c_img = c_img(:,:,1:3); % Transparency is not used, so ignore it
        
        clear_cache; % Clear the fnc cache as we are evaluating again
        
        L.summary_data.ImageErrorSingleView = sum(error_foo{1}({c_img}));
        
        summary_data = L.summary_data;
        save([paths_str.summary '.mat'], 'summary_data', '-append');
        
        append_to_summary_file(paths_str.summary, ['ImageErrorSingleView is '...
            num2str(L.summary_data.ImageErrorSingleView)]);
    end
    
    %% Move the best per iteration images to a folder
    best_img_iter_path = [output_img_folder 'best-iter*'];
    if ~isempty(dir(best_img_iter_path)) % Check if any image was generated
        for i=1:num_goal
            istr = num2str(i);
            best_img_iter_folder = [output_img_folder 'best-iter-Cam' istr];
            
            mkdir(best_img_iter_folder);
            movefile([best_img_iter_path '-Cam' istr '.tif'], best_img_iter_folder);
        end
    end
    
    %% Resource clean up after execution
    
    % If running in batch mode, exit matlab
    if(isBatchMode())
        move_file( logfile, [output_img_folder 'matlab.log'] );
        copy_maya_log_files(logfile, output_img_folder, ports);
        exit;
    else
        % If GUI running, show the computed final image
        for i=1:num_goal
            istr = num2str(i);
            figure('Name', ['Optimized Camera' istr] );
            optimized_img = imread([output_img_folder 'optimized-Cam' istr ...
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
            if(exist('ports', 'var'))
                copy_maya_log_files(logfile, output_img_folder, ports);
            end
        end
        exit;
    else
        rethrow(ME);
    end
end
end