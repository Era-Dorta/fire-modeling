function [ error ] = heat_map_fitness_gaussprocess( heat_map_v, xyz, whd, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
    port, mrLogPath, goal_img)
%HEAT_MAP_FITNESS_GAUSSPROCESS Heat map fitness function
%   Same as HEAT_MAP_FITNESS_GAUSSPROCESS, but uses a gaussian process to
%   estimate the histograms
%
%   See also HEAT_MAP_FITNESS
persistent IS_INITIALIZED GP N_GOAL NORM_FACTOR BIN_SIZE BIN_RANGE

if isempty(IS_INITIALIZED) || IS_INITIALIZED == false
    IS_INITIALIZED = true;
    
    % Check on initialization that it is the right error function, ideally
    % it should be done on each call, but this function needs to be heavily
    % optimized
    assert(isequal(error_foo{1}, @histogramError) || isequal(error_foo{1}, @histogramErrorOpti), ...
        'Only histogram error functions are allowed');
    
    data_folder = '~/maya/projects/fire/images/test78_like_72_4x4x4_raw/render_approx_data0';
    
    load([data_folder '/data.mat']);
    
    if(exist([data_folder '/GaussProcess.mat'],'file'))
        load([data_folder '/GaussProcess.mat']);
    else
        % Heatmaps are already in the right format
        % X = heat_maps
        
        % Flatten out the histograms
        Y = cellfun(@(x) [x(1, bin_range), x(2, bin_range), x(3, bin_range)], ...
            histocounts, 'UniformOutput', false);
        Y = cell2mat(Y);
        
        % Input:
        %  X = N x Q Input Data (N = no. samples, Q = input dimensions)
        %  Y = N x D Output Data (N = no. samples again, D = output dimensions
        %
        disp('Learning Gauss Process parameters');
        startGauss = tic;
        GP = GaussProcess(heat_maps, Y, [], [], [], true);
        GP = GP.LearnKernelParameters();
        save([data_folder '/GaussProcess.mat'],'GP','-v7.3');
        toc(startGauss);
    end
    
    N_GOAL(1, :) = histcounts( goal_img(:, :, 1), edges);
    N_GOAL(2, :) = histcounts( goal_img(:, :, 2), edges);
    N_GOAL(3, :) = histcounts( goal_img(:, :, 3), edges);
    
    % Normalization factor is the inverse of the number of pixels
    NORM_FACTOR = 1 / numel(goal_img);
    
    BIN_SIZE = size(bin_range, 2);
    BIN_SIZE = [1, BIN_SIZE, BIN_SIZE + 1, BIN_SIZE * 2, BIN_SIZE * 2 + 1, ...
        BIN_SIZE * 3];
    
    BIN_RANGE = bin_range;
end
% If the predicted confidence in the value is lower than the threshold
% the heat map will be rendered
prediction_tolerance = 100;

% Get predictions:
%  yEst = estimated value for each row of X_test
%  yEstVar = estimated variance for each row of X_test
[pred_histo, pred_histo_var] = GP.Predict(heat_map_v);

if(pred_histo_var - 0.9990 > 0.1)
    disp(pred_histo_var);
end

num_error_foos = size(error_foo, 2);
error = zeros(num_error_foos, size(heat_map_v, 1));

for pop=1:size(heat_map_v, 1)
    if(pred_histo_var(pop) < prediction_tolerance)
        % Compute the error as in Dobashi et. al. 2012 using the prediction
        % from the Gaussian Proccess
        error(pop) = (sum(abs(pred_histo(pop, BIN_SIZE(1):BIN_SIZE(2)) - N_GOAL(1, BIN_RANGE))) + ...
            sum(abs(pred_histo(pop, BIN_SIZE(3):BIN_SIZE(4)) - N_GOAL(2, BIN_RANGE))) + ...
            sum(abs(pred_histo(pop, BIN_SIZE(5):BIN_SIZE(6)) - N_GOAL(3, BIN_RANGE)))) * NORM_FACTOR;
    else
        error(pop) = heat_map_fitness( heat_map_v(pop,:), xyz, whd, error_foo, ...
            scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
            port, mrLogPath, goal_img);
    end
end

end

