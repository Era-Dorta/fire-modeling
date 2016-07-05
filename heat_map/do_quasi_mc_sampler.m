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
    mkdir(output_img_folder, 'data');
    render_folder = fullfile(output_img_folder, 'data');
    
    %% Maya initialization
    % TODO Render once and test if an image is created, if not -> activate
    % first camera -> test again, if still fails -> exit gracefully
    if isBatchMode()
        empty_maya_log_files(logfile, ports);
    end
    
    maya_common_initialization(maya_send, ports, opts.scene_name, ...
        opts.fuel_type, num_goal, opts.is_mr);
    
    %% Fitness function definition
    dist_fnc = get_dist_fnc_from_file(opts);
    
    %% Solver call
    disp('Start sampling');
    
    temp_path = fullfile(render_folder, 'tempimage');
    
    heat_map_v = init_heat_map.v;
    heat_map_v(:) = mean([opts.UB, opts.LB]);
    
    heat_map_path = fullfile(render_folder, 'heat-map1.raw');
    
    heat_map = struct('xyz', init_heat_map.xyz, 'v', heat_map_v, 'size', ...
        init_heat_map.size, 'count', init_heat_map.count);
    
    save_raw_file(heat_map_path, heat_map);
    
    render_single_hm( maya_send{1}, num_goal, heat_map_path, temp_path);
    
    img_path = fullfile(render_folder, 'fireimage1.tif');
    movefile([temp_path '1.tif'], img_path);
    
    init_img = imread(img_path);
    init_img = init_img(:,:,1:3);
    
    max_norm = zeros(init_heat_map.count, 1) + opts.UB;
    max_norm = max_norm - opts.LB;
    max_norm = norm(max_norm);
    
    edges = linspace(0, 255, opts.n_bins+1);
    
    norm_factor = 1 / sum(img_mask(:) == 1);
    assert(~isinf(norm_factor));
    
    ori_histo = getImgRGBHistogram( init_img, img_mask, opts.n_bins, edges);
    ori_histo = ori_histo * norm_factor;
    
    mean_dist_rgb = zeros(1, size(ori_histo, 1));
    
    for i=2:opts.num_samples
        
        istr = num2str(i);
        
        % Generate a random perturbation of the solution
        perturbation = rand(init_heat_map.count, 1) - 0.5;
        
        % Normalize each sample
        perturbation = perturbation / norm(perturbation);
        
        % Scale each sample to given norm
        perturbation = perturbation * (max_norm / opts.sample_divisions);
        
        heat_map_v = heat_map_v + perturbation;
        
        heat_map_v = max(heat_map_v, opts.LB);
        heat_map_v = min(heat_map_v, opts.UB);
        
        heat_map_path = fullfile(render_folder, ['heat-map' istr '.raw']);
        
        heat_map = struct('xyz', init_heat_map.xyz, 'v', heat_map_v, 'size', ...
            init_heat_map.size, 'count', init_heat_map.count);
        
        save_raw_file(heat_map_path, heat_map);
        
        render_single_hm( maya_send{1}, num_goal, heat_map_path, temp_path);
        
        img_path = fullfile(render_folder, ['fireimage' istr '.tif']);
        movefile([temp_path '1.tif'], img_path);
        
        I = imread(img_path);
        I = I(:,:,1:3);
        
        i_histo = getImgRGBHistogram( I, img_mask, opts.n_bins, edges);
        i_histo = i_histo * norm_factor;
        
        for j=1:size(i_histo, 1)
            mean_dist_rgb(j) = mean_dist_rgb(j) + ...
                dist_fnc(i_histo(j, :), ori_histo(j, :));
        end
        
        ori_histo = i_histo;
    end
    
    mean_dist_rgb = mean_dist_rgb / opts.num_samples;
    
    disp(['Mean RGB distance is ' num2str(mean_dist_rgb)]);
    
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