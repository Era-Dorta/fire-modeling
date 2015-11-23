function [ heat_map_v, best_error, exitflag] = do_genetic_solve_resample( ...
    max_ite, time_limit, LB, UB, init_heat_map, fitness_foo, paths_str, ...
    sendMayaScript, port)
% Genetics Algorithm solver for heat map reconstruction with heat map
% resampling scheme for faster convergence

[summarydir, summaryname, summaryext] = fileparts(paths_str.summary);

paths_str.summary = [summarydir '/' summaryname];

%% Options for the ga
% Get default values
options = gaoptimset(@ga);
options.EliteCount = 1;
options.Display = 'iter'; % Give some output on each iteration
options.MutationFcn = @mutationadaptfeasible;

% The volume size will be at least this small, as we are recursively
% dividing by 2 the original size, it might be smaller if there is no
% integer i such that init_heat_map.size / 2^i == 32
minimumVolumeSize = 32;

% Population size for the maximum resolution
populationInitSize = 15;

% Factor by which the population increases for a GA run with half of the
% resolution, population of a state i will be initSize * (scale ^ i)
populationScale = 2;

A = [];
b = [];
Aeq = [];
beq = [];
nonlcon = [];

%% Down sample the heat map
disp('Down sampling the density volume');
d_heat_map{1} = init_heat_map;
num_ite = 1;
while max(d_heat_map{end}.size) > minimumVolumeSize
    d_heat_map{end + 1} = resampleHeatMap(d_heat_map{end}, 'down');
    
    % Save the downsampled in a file as we are going to use it as the
    % corresponding density for the downsampled heat map in Maya
    d_heat_map{end}.filename = [paths_str.output_folder 'density' ...
        num2str(d_heat_map{end}.size(1)) '.raw'];
    
    save_raw_file(d_heat_map{end}.filename, d_heat_map{end});
    
    num_ite = num_ite + 1;
end

% Divide the time equally between each GA loop
options.TimeLimit = time_limit / num_ite;

% Flip the elements so that they go in increasing size
d_heat_map = flip(d_heat_map);

disp(['Done down sampling, will run the GA ' num2str(num_ite) ' times']);

mainStartTime = tic;

%% Main optimization loop
for i=1:num_ite
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    disp([num2str(i) '/' num2str(num_ite) ' of main optimization loop, current volume size ' ...
        num2str(d_heat_map{i}.size)]);
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    
    size_str = num2str(d_heat_map{i}.size(1));
    
    %% Iteration dependant GA parameters
    
    % Start with large population and decrease it
    options.PopulationSize = populationInitSize * (populationScale ^ ...
        (num_ite - i));
    
    disp(['Population size ' num2str(options.PopulationSize) ', number of '...
        'variables ' num2str(d_heat_map{i}.count)]);
    
    options.Generations = max(fix(max_ite / options.PopulationSize), 1);
    
    % Upper and lower bounds
    LB1 = ones(d_heat_map{i}.count, 1) * LB;
    UB1 = ones(d_heat_map{i}.count, 1) * UB;
    
    % Function executed on each iteration, there is a PlotFcns too, but it
    % creates a figure outside of our control and it makes the plotting and
    % saving figures too dificult
    plotf = @(options,state,flag)gaplotbestcustom(options, state, flag, ...
        [paths_str.errorfig size_str]);
    
    % Matlab is using cputime to measure time limits in GA and Simulated
    % Annealing solvers, which just doesn't work with multiple cores and
    % multithreading even if the value is scaled with the number of cores.
    % Add a custom function to do the time limit check
    
    startTime = tic;
    timef = @(options, state, flag)ga_time_limit( options, state, flag, startTime);
    
    options.OutputFcns = {plotf, timef};
    
    %% Set the initial population function generator
    init_population_path = [paths_str.output_folder 'InitialPopulation' ...
        size_str '.mat'];
    if i == 1
        % Random initial population
        options.CreationFcn = @(x, y, z)gacreationrandom(x , y, z, init_population_path);
        
        % Linearly spaced population
        % options.CreationFcn = @(x, y, z)gacreationlinspace(x , y, z, ...
        %     init_population_path);
    else
        % Create from upsampling the result of the previous iteration
        options.CreationFcn = @(x, y, z)gacreationupsample(x , y, z, scores, ...
            out_population, d_heat_map{i - 1}, d_heat_map{i}, ...
            init_population_path);
    end
    
    %% Fitness function
    new_fitness_foo = @(v)fitness_foo(v, d_heat_map{i}.xyz, d_heat_map{i}.size);
    
    %% Send Maya iteration specific parameters
    disp('Setting size parameters in Maya');
    % In Maya the cube goes from -1 to 1 in each dimension, half a voxel size
    % which is the optimal step size is computed as the inverse of the size
    march_size = 1 / min(d_heat_map{i}.size) ;
    
    % Set an appropriate march increment to reduced voxel data
    cmd = ['setAttr fire_volume_shader.march_increment ' num2str(march_size)];
    sendToMaya(sendMayaScript, port, cmd);
    
    % Set the density file to the reduced voxel data
    % We need the full path to the file or the rendering will fail
    cmd = 'setAttr -type \"string\" fire_volume_shader.density_file \"';
    cmd = [cmd '$HOME/' d_heat_map{i}.filename(3:end) '\"'];
    sendToMaya(sendMayaScript, port, cmd);
    
    %% Call the genetic algorithm optimization for the first
    disp('Starting GA optimization');
    
    [heat_map_v, best_error, exitflag, ~, out_population, scores] =  ...
        ga( new_fitness_foo, d_heat_map{i}.count, A, b, Aeq, beq, LB1, UB1, ...
        nonlcon, options);
    
    totalTime = toc(startTime);
    disp(['GA optimization iteration time ' num2str(totalTime)]);
    
    %% Save summary file
    % In the summary file just say were the init population file was saved
    init_population = options.InitialPopulation;
    options.InitialPopulation = init_population_path;
    
    save_summary_file([paths_str.summary size_str summaryext],  ...
        'Genetic Algorithms Resample', best_error, d_heat_map{i}.size(1), options, ...
        LB1(1), UB1(1), totalTime);
    
    options.InitialPopulation = init_population;
    
    % Save information files for the intermediate optimizations, the
    % information for the last one will be saved outside of this function
    if i < num_ite
        %% Save the best heat map in a raw file
        heat_map_name = ['heat-map' size_str '.raw'];
        heat_map_path = [paths_str.output_folder heat_map_name];
        
        disp(['Current best heat map saved in ' heat_map_path]);
        
        heat_map = struct('xyz', d_heat_map{i}.xyz, 'v', heat_map_v', 'size', ...
            d_heat_map{i}.size, 'count', d_heat_map{i}.count);
        
        save_raw_file(heat_map_path, heat_map);
        
        %%  Render the best image again
        % Set the heat map file as temperature file
        % It cannot have ~, and it has to be the full path, so use the HOME var
        cmd = 'setAttr -type \"string\" fire_volume_shader.temperature_file \"';
        cmd = [cmd '$HOME/' heat_map_path(3:end) '\"'];
        sendToMaya(sendMayaScript, port, cmd);
        
        % Set the folder and name of the render image
        best_im_name = ['optimized' size_str];
        cmd = 'setAttr -type \"string\" defaultRenderGlobals.imageFilePrefix \"';
        cmd = [cmd paths_str.imprefixpath best_im_name '\"'];
        sendToMaya(sendMayaScript, port, cmd);
        
        % Give the user some progress information
        best_im_path = [paths_str.output_folder best_im_name '.tif'];
        disp(['Rendering current best image in ' best_im_path ]);
        
        % Render the image
        tic;
        cmd = 'Mayatomr -render -camera \"camera1\" -renderVerbosity 5';
        sendToMaya(sendMayaScript, port, cmd, 1, paths_str.mrLogPath);
        disp(['Image rendered in ' num2str(toc) ]);
    end
end

disp(['Total optimization time was ' num2str(toc(mainStartTime))]);

end

