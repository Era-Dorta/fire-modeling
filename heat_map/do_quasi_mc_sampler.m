function do_quasi_mc_sampler(args_path, ports, logfile)
%DO_QUASI_MC_SAMPLER Sample histogram changes
%   DO_QUASI_MC_SAMPLER(ARGS_PATH, PORTS, LOGFILE)
%   ARGS_PATH is the path of a .mat file with arguments for the
%   optimization
%   PORTS is a vector containing port numbers that Maya is listening to
%   LOGFILE is only required when running in batch mode, is a string with
%   the path of the current log file

%% Parameter initalization
% N.B. If Matlab is started from the GUI and custom paths are used for the
% Maya plugins, Matlab will not read the Maya path variables that were
% defined in the .bashrc file and the render script will fail, a
% workouround is to redefine them here:
% setenv('MAYA_SCRIPT_PATH', 'scripts path');
% setenv('MI_CUSTOM_SHADER_PATH', ' shaders include path');
% setenv('MI_LIBRARY_PATH', 'shaders path');
close all;
% Add the subfolders of heat map to the Matlab path
addpath(genpath(fileparts(mfilename('fullpath'))));
% gcp;
%% Setting clean up functions
% Clear all the functions, includes gcp clear
clearCloseObj = onCleanup(@clear_cache);

%% Avoid data overwrites by always creating a new folder
try
    if(nargin < 2)
        error('Not enough input arguments.');
    end
    
    if(isBatchMode() && nargin < 3)
        error('Logfile name is required when running in batch mode');
    end
    
    opts = load(args_path);
    
    rng(opts.rand_seed);
    
    % Find the last folder
    dir_num = 0;
    while(exist([opts.scene_img_folder 'qmc_sampler_' num2str(dir_num)], 'dir') == 7)
        dir_num = dir_num + 1;
    end
    
    % Create a new folder to store the data
    output_img_folder = [opts.scene_img_folder 'qmc_sampler_' num2str(dir_num) '/'];
    output_img_folder_name = ['qmc_sampler_' num2str(dir_num) '/'];
    
    %% Read goal and mask image/s
    num_goal = numel(opts.goal_img_path);
    
    % For MSE resize the goal image to match the synthetic image
    if(isequal(opts.error_foo{1}, @MSE))
        resize_goal = true;
    else
        resize_goal = false;
    end
    [ ~, ~, ~, img_mask ] = readGoalAndMask( ...
        opts.goal_img_path,  opts.in_img_path, opts.mask_img_path,  ...
        opts.goal_mask_img_path, resize_goal);
    img_mask = img_mask{1};
    
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
    
    %% Volumetric data initialization
    init_heat_map = read_raw_file([opts.project_path opts.raw_file_path]);
    init_heat_map.v = init_heat_map.v * opts.raw_temp_scale + ...
        opts.raw_temp_offset;
    
    %% Ouput folder
    disp(['Creating new output folder ' output_img_folder]);
    mkdir(opts.scene_img_folder, output_img_folder_name);
    
    %% Maya initialization
    % TODO Render once and test if an image is created, if not -> activate
    % first camera -> test again, if still fails -> exit gracefully
    if isBatchMode()
        empty_maya_log_files(logfile, ports);
    end
    
    maya_common_initialization(maya_send, ports, opts.scene_name, ...
        opts.fuel_type, num_goal, opts.is_mr);
    
    %% Distance function
    dist_fnc = get_dist_fnc_from_file(opts);
    
    %% Create the samples
    totalTime = tic;
    
    heat_map_v = zeros(opts.num_samples, init_heat_map.count);
    
    heat_map_v(1,:) = mean([opts.UB, opts.LB]);
    
    max_norm = zeros(init_heat_map.count, 1) + opts.UB;
    max_norm = max_norm - opts.LB;
    max_norm = norm(max_norm);
    
    for i=2:opts.num_samples
        
        % Generate a random perturbation of the solution
        perturbation = rand(1, init_heat_map.count) - 0.5;
        
        % Normalize each sample
        perturbation = perturbation / norm(perturbation);
        
        % Scale each sample to given norm
        perturbation = perturbation * (max_norm / opts.sample_divisions);
        
        heat_map_v(i,:) = heat_map_v(i-1,:) + perturbation;
        
        heat_map_v(i,:) = max(heat_map_v(i,:), opts.LB);
        heat_map_v(i,:) = min(heat_map_v(i,:), opts.UB);
        
    end
    
    %% Render the samples
    render_ga_population_par( heat_map_v, opts, maya_send, num_goal, ...
        init_heat_map, output_img_folder_name, 'data', false );
    
    %% Compare the histogram changes for each of them
    render_folder = fullfile(output_img_folder, 'dataCam1');
    
    edges = linspace(0, 255, opts.n_bins+1);
    norm_factor = 1 / sum(img_mask(:) == 1);
    assert(~isinf(norm_factor));
    
    img_path = fullfile(render_folder, 'fireimage1.tif');
    
    init_img = imread(img_path);
    init_img = init_img(:,:,1:3);
    
    ori_histo = getImgRGBHistogram( init_img, img_mask, opts.n_bins, edges);
    ori_histo = ori_histo * norm_factor;
    
    histo_dim = size(ori_histo, 1);
    mean_dist_rgb = zeros(1, histo_dim);
    
    for i=2:opts.num_samples
        istr = num2str(i);
        
        img_path = fullfile(render_folder, ['fireimage' istr '.tif']);
        
        I = imread(img_path);
        I = I(:,:,1:3);
        
        i_histo = getImgRGBHistogram( I, img_mask, opts.n_bins, edges);
        i_histo = i_histo * norm_factor;
        
        for j=1:histo_dim
            mean_dist_rgb(j) = mean_dist_rgb(j) + ...
                dist_fnc(i_histo(j, :), ori_histo(j, :));
        end
        
        ori_histo = i_histo;
    end
    
    mean_dist_rgb = mean_dist_rgb / opts.num_samples;
    
    totalTime = toc(totalTime);
    
    disp(['Mean RGB distance is ' num2str(mean_dist_rgb)]);
    
    %% Save summary file
    summary_data = opts;
    summary_data.NumMaya = numMayas;
    summary_data.Ports = ports;
    summary_data.IsBatchMode = isBatchMode();
    summary_data.FuelName = get_fuel_name(opts.fuel_type);
    summary_data.OptimizationMethod = 'Quasi Monte Carlo sampler';
    summary_data.HeatMapSize = init_heat_map.size;
    summary_data.HeatMapNumVariables = init_heat_map.count;
    summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
    summary_data.MeanRGBDistance = mean_dist_rgb;
    
    save_summary_file(fullfile(output_img_folder, 'summary_file'), ...
        summary_data, []);
    
    %% Resource clean up after execution
    
    % If running in batch mode, exit matlab
    if(isBatchMode())
        move_file( logfile, [output_img_folder 'matlab.log'] );
        copy_maya_log_files(logfile, output_img_folder, ports);
        exit;
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
        exit(1);
    else
        rethrow(ME);
    end
end
end