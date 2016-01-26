function [ error ] = heat_map_fitness_gp_pca( heat_map_v, xyz, whd, error_foo, ...
    scene_name, scene_img_folder, output_img_folder_name, sendMayaScript, ...
    port, mrLogPath, goal_img)
%HEAT_MAP_FITNESS_GP_PCA Heat map fitness function
%   Same as HEAT_MAP_FITNESS_GP_PCA, but uses a gaussian process to
%   estimate the histograms and uses pca to reduce the histogram
%   dimensionality
%
%   See also HEAT_MAP_FITNESS
persistent IS_INITIALIZED GP N_GOAL NORM_FACTOR BIN_SIZE BIN_RANGE COEFF ...
    STD_Y MU

if isempty(IS_INITIALIZED) || IS_INITIALIZED == false
    IS_INITIALIZED = true;
    
    % Check on initialization that it is the right error function, ideally
    % it should be done on each call, but this function needs to be heavily
    % optimized
    assert(isequal(error_foo{1}, @histogramError) || isequal(error_foo{1}, @histogramErrorOpti), ...
        'Only histogram error functions are allowed');
    
    data_folder = '~/maya/projects/fire/images/test78_like_72_4x4x4_raw/render_approx_data2';
    
    disp('Loading training data');
    loadtime = tic;
    load([data_folder '/data.mat']);
    loadtime = toc(loadtime);
    disp(['Done loading training data ' num2str(loadtime) ' seconds']);
    
    if(exist([data_folder '/GaussProcessPCA.mat'],'file'))
        disp('Loading GaussProcess');
        loadtime = tic;
        load([data_folder '/GaussProcessPCA.mat']);
        loadtime = toc(loadtime);
        disp(['Done loading GaussProcess ' num2str(loadtime) ' seconds']);
    else
        % Heatmaps are already in the right format
        % X = heat_maps
        
        % Flatten out the histograms
        Y = cellfun(@(x) [x(1, bin_range), x(2, bin_range), x(3, bin_range)], ...
            histocounts, 'UniformOutput', false);
        Y = cell2mat(Y);
        
        % Standarize the data, pca only does the mean substraction but
        % doing the scaling is also important because the "explained"
        % coefficients change significantly
        MU = mean(Y);
        STD_Y = std(Y);
        Ycentered = bsxfun(@minus, Y, MU);
        Ycentered = bsxfun(@rdivide, Ycentered, STD_Y);
        
        [COEFF, ~, ~, ~, explained] = pca(Ycentered);
        
        % Keep dimensions until 99.5% of the variability in the data is
        % explained
        n_components=1;
        while(n_components < size(explained, 1) && ...
                sum(explained(1:n_components)) < 99.5)
            n_components = n_components + 1;
        end
        
        COEFF = COEFF(:,1:n_components);
        
        % Reduce the data dimensionality
        Yreduced = Ycentered * COEFF;
        
        % Input:
        %  X = N x Q Input Data (N = no. samples, Q = input dimensions)
        %  Y = N x D Output Data (N = no. samples again, D = output dimensions
        %
        disp('Learning Gauss Process parameters');
        startGauss = tic;
        
        % There are no experimental errors in our "measurements" of the
        % heatmaps, set it to 1/eps instead of 1/0 to avoid using inf
        inv_data_error = 1/eps;
        
        GP = GaussProcess(heat_maps, Yreduced, [], [], inv_data_error, true);
        GP = GP.LearnKernelParameters();
        
        % Do one prediction, this precomputes certain values in GP that
        % will accelerate future calls to Predict
        [~, ~, GP] = GP.Predict(heat_maps(1, :));
        save([data_folder '/GaussProcessPCA.mat'],'GP', 'COEFF', 'STD_Y', ...
            'MU', '-v7.3');
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
prediction_tolerance = 0.2;

% Get predictions:
%  yEst = estimated value for each row of X_test
%  yEstVar = estimated variance for each row of X_test
[pred_histo, pred_histo_var] = GP.PredictNoChecks(heat_map_v);

num_error_foos = size(error_foo, 2);
error = zeros(num_error_foos, size(heat_map_v, 1));

for pop=1:size(heat_map_v, 1)
    if(pred_histo_var(pop) < prediction_tolerance)
        
        % Reconstruct the histogram from the reduced pca dimensions, in the
        % reconstruction we might get an odd negative number, clamp it to 0
        pred_histo = max((pred_histo * COEFF') .* STD_Y + MU, 0);
        
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

