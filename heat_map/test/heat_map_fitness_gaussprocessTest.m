%test heat_map_fitness_gaussprocess
% This script doesn't check for the validity of the fitness function, it
% only checks for the results given by GaussProcess variables used in it

% Tolerance for float comparison
tol = 0.00001;
error_th = 10; % No more than 10 histocounts wrong

data_folder = '~/maya/projects/fire/images/test78_like_72_4x4x4_raw/render_approx_data2';

% Load the train data
train_data_path = [data_folder '/data.mat'];
if(exist(train_data_path,'file'))
    load(train_data_path);
else
    error(['File ' train_data_path ' not found']);
end

% Load the test data
test_data_path = [data_folder '/test-data.mat'];
if(exist(test_data_path,'file'))
    load(test_data_path);
else
    error(['File ' test_data_path ' not found']);
end

% Load the trained model
model_data_path = [data_folder '/GaussProcess.mat'];
if(exist(model_data_path,'file'))
    load(model_data_path);
else
    error(['File ' model_data_path ' not found']);
end

% Flatten out the histograms
Y = cellfun(@(x) [x(1, bin_range), x(2, bin_range), x(3, bin_range)], ...
    histocounts, 'UniformOutput', false);
Y = cell2mat(Y);

test_Y = cellfun(@(x) [x(1, bin_range), x(2, bin_range), x(3, bin_range)], ...
    test_histocounts, 'UniformOutput', false);
test_Y = cell2mat(test_Y);

%% Test with train data

pred_histo = GP.PredictNoChecks(heat_maps);

pred_error = zeros(size(heat_maps, 1), 1);
for i=1:size(heat_maps, 1)
    pred_error(i) = norm(pred_histo(i, :) - Y(i, :));
end

assert(mean(pred_error) < error_th, 'Failed with train data');

%% Test with test data

pred_histo = GP.PredictNoChecks(test_heat_maps);

pred_error = zeros(size(test_heat_maps, 1), 1);
for i=1:size(test_heat_maps, 1)
    pred_error(i) = norm(pred_histo(i, :) - test_Y(i, :));
end

assert(mean(pred_error) < error_th, 'Failed with test data');