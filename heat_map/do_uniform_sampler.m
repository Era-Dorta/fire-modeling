function do_uniform_sampler(args_path, ports, logfile)
%DO_UNIFORM_SAMPLER Sample histogram changes
%   DO_UNIFORM_SAMPLER(ARGS_PATH, PORTS, LOGFILE)
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
    while(exist([opts.scene_img_folder 'uniform_sampler_' num2str(dir_num)], 'dir') == 7)
        dir_num = dir_num + 1;
    end
    
    % Create a new folder to store the data
    output_img_folder = [opts.scene_img_folder 'uniform_sampler_' num2str(dir_num) '/'];
    output_img_folder_name = ['uniform_sampler_' num2str(dir_num) '/'];
    
    %% Read goal and mask image/s
    num_goal = numel(opts.goal_img_path);
    
    [ ~, ~, ~, img_mask ] = readGoalAndMask( ...
        opts.goal_img_path,  opts.in_img_path, opts.mask_img_path,  ...
        opts.goal_mask_img_path, false);
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
    if isBatchMode()
        empty_maya_log_files(logfile, ports);
    end
    
    maya_common_initialization(maya_send, ports, opts.scene_name, ...
        opts.fuel_type, num_goal, opts.is_mr);
    
    %% Distance function
    dist_fnc = get_dist_fnc_from_file(opts);
    
    %% Maximum distance and edges for the distance histogram
    % norm(ub - lb)
    max_norm = zeros(init_heat_map.count, 1) + opts.UB;
    max_norm = max_norm - opts.LB;
    max_norm = norm(max_norm);
    
    edges_s = linspace(0, max_norm, opts.samples_n_bins + 1);
    edges_s(end) = edges_s(end) + eps;
    
    %% Simple random sampling and plot histogram
    show_random_sampling = false;
    if show_random_sampling
        heat_map_v = rand(opts.num_samples, init_heat_map.count);
        heat_map_v = fitToRange(heat_map_v, 0, 1, opts.LB, opts.UB);
        
        h_norm = zeros(1, opts.num_samples/2);
        j=1;
        for i=2:2:opts.num_samples
            h_norm(j) = norm(heat_map_v(i-1,:) - heat_map_v(i,:));
            j = j+1;
        end
        
        h_count = histcounts(h_norm, edges_s);
        h_count = h_count / sum(h_count);
        
        hold on;
        bar(linspace(0, 100, opts.samples_n_bins), h_count);
        xlim([0,100]);
        xlabel('Step size (% of max step size)');
        ylabel('Normalised frequency');
        hold off;
    end
    
    %% Create the samples
    % For each sample we need two heat maps
    heat_map_v = cell(opts.samples_n_bins, 1);
    
    if opts.num_samples < 2 * opts.samples_n_bins
        error('num_samples must be >= 2 * samples_n_bins');
    end
    
    opts.num_samples = round((opts.num_samples * 2)/opts.samples_n_bins);
    if mod(opts.num_samples, 2) ~= 0
        opts.num_samples = opts.num_samples + 1;
    end
    
    totalTime = tic;
    
    % Norm distance between histogram bins
    norm_step = edges_s(2) - edges_s(1);
    
    % Copy data to have more efficient parfor evaluation
    num_samples = opts.num_samples;
    hm_count = init_heat_map.count;
    lb = opts.LB;
    ub = opts.UB;
    
    diff_b_step = ((ub - lb) / 2) / opts.samples_n_bins;
    
    i_next = ones(opts.samples_n_bins, 1);
    
    % Parfor as it is quite computationally intensive
    for j=1:opts.samples_n_bins
        nlb(1) = lb + diff_b_step * (j - 1);
        nub(1) = ub - diff_b_step * j;
        nlb(2) = lb + diff_b_step * j;
        nub(2) = ub - diff_b_step * (j - 1);
        
        for i=2:2:num_samples
            
            idx = randi(hm_count, 1, 1);
            
            % Generate random point and its mirror
            heat_map_v1 = rand(1, hm_count);
            heat_map_v2 = 1 - heat_map_v1;
            
            s_val1 = heat_map_v1(idx);
            
            % Put all the values inside the current hypercube
            heat_map_v1 = fitToRange(heat_map_v1, 0, 1, nlb(1), nub(2));
            heat_map_v2 = fitToRange(heat_map_v2, 0, 1, nlb(1), nub(2));
            
            % Make one dimension be in the band of the edge of the
            % hypercube so that the inside is not sampled
            if rand() > 0.5
                heat_map_v1(idx) = fitToRange(s_val1, 0, 1, nlb(1), nlb(2));
                heat_map_v2(idx) = fitToRange(1 - s_val1, 0, 1, nub(1), nub(2));
            else
                heat_map_v1(idx) = fitToRange(s_val1, 0, 1, nub(1), nub(2));
                heat_map_v2(idx) = fitToRange(1 - s_val1, 0, 1, nlb(1), nlb(2));
            end
            
            h_norm = norm(heat_map_v1 - heat_map_v2);
            
            % Find where the pair sample lies according to the norm
            j_real = discretize(h_norm, edges_s);
            
            ii = i_next(j_real);
            
            heat_map_v{j_real}(ii,:) = heat_map_v1;
            heat_map_v{j_real}(ii + 1,:) = heat_map_v2;
            
            i_next(j_real) = ii + 2;
        end
    end
    
    %% Render the samples
    for j=1:opts.samples_n_bins
        jstr = num2str(j);
        render_ga_population_par( heat_map_v{j}, opts, maya_send, num_goal, ...
            init_heat_map, output_img_folder_name, ['data' jstr], false );
    end
    
    %% Compare the histogram changes for each of them
    edges = linspace(0, 255, opts.n_bins+1);
    histo_dim = 3;
    mean_dist_rgb = zeros(opts.samples_n_bins, histo_dim);
    std_dist_rgb = zeros(opts.samples_n_bins, histo_dim);
    
    norm_factor = 1 / sum(img_mask(:) == 1);
    assert(~isinf(norm_factor));
    
    dist_rgb = zeros(opts.num_samples/2, histo_dim);
    
    for l=1:opts.samples_n_bins
        lstr = num2str(l);
        disp(['Bin ' lstr]);
        render_folder = fullfile(output_img_folder, ['data' lstr 'Cam1' ]);
        
        k = 1;
        for i=1:2:opts.num_samples
            istr = num2str(i);
            
            img_path = fullfile(render_folder, ['fireimage' istr '.tif']);
            
            I = imread(img_path);
            I = I(:,:,1:3);
            
            ori_histo = getImgRGBHistogram( I, img_mask, opts.n_bins, edges);
            ori_histo = ori_histo * norm_factor;
            
            istr = num2str(i+1);
            
            img_path = fullfile(render_folder, ['fireimage' istr '.tif']);
            
            I = imread(img_path);
            I = I(:,:,1:3);
            
            i_histo = getImgRGBHistogram( I, img_mask, opts.n_bins, edges);
            i_histo = i_histo * norm_factor;
            
            for j=1:histo_dim
                dist_rgb(k, j) = dist_fnc(i_histo(j, :), ori_histo(j, :));
            end
            
            k = k + 1;
        end
        
        mean_dist_rgb(l,:) = mean(dist_rgb);
        std_dist_rgb(l,:) = std(dist_rgb);
        
        disp(['    Mean RGB distance is ' num2str(mean_dist_rgb(l,:))]);
        disp(['    Std RGB distance is ' num2str(std_dist_rgb(l,:))]);
    end
    totalTime = toc(totalTime);
    
    % Restore the previous value for the number of samples
    opts.num_samples = opts.num_samples / 2 * opts.samples_n_bins;
    
    %% Save data
    summary_data = opts;
    summary_data.NumMaya = numMayas;
    summary_data.Ports = ports;
    summary_data.IsBatchMode = isBatchMode();
    summary_data.FuelName = get_fuel_name(opts.fuel_type);
    summary_data.OptimizationMethod = 'Uniform sampler';
    summary_data.HeatMapSize = init_heat_map.size;
    summary_data.HeatMapNumVariables = init_heat_map.count;
    summary_data.OptimizationTime = [num2str(totalTime) ' seconds'];
    summary_data.MeanRGBDistance = mean_dist_rgb;
    summary_data.StdRGBDistance = std_dist_rgb;
    summary_data.StepSize = edges_s;
    
    save_summary_file(fullfile(output_img_folder, 'summary_file'), ...
        summary_data, []);
    
    save(fullfile(output_img_folder, 'OutData.mat'), 'dist_rgb');
    
    %% Plot the results
    compare_uniform_sampling_tests(output_img_folder, summary_data);
    
    %% Compress the output data
    % Cannot use full paths so create the tar.gz and then move it
    for l=1:opts.samples_n_bins
        lstr = num2str(l);
        render_folder = fullfile(output_img_folder, ['data' lstr 'Cam1' ]);
        tar(['data' lstr '.tar.gz'], render_folder);
        movefile(['data' lstr '.tar.gz'], output_img_folder);
        rmdir(render_folder,'s');
    end
    
    %% Copy arguments file
    copyfile(args_path, output_img_folder);
    
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