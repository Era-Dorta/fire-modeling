%test heat_map_fitness_gaussprocess
% This script doesn't check for the validity of the fitness function, it
% only checks for the results given by GaussProcess variables used in it

% Tolerance for float comparison
tol = 0.00001;
error_th = 10; % No more than 10 histocounts wrong

data_folder = '~/maya/projects/fire/images/test78_like_72_4x4x4_raw/render_approx_data0';

% Load the train data
train_data_path = [data_folder '/data.mat'];
if(exist(train_data_path,'file'))
    train = load(train_data_path);
else
    error(['File ' train_data_path ' not found']);
end

% Load the test data
test_data_path = [data_folder '/test-data.mat'];
if(exist(test_data_path,'file'))
    test = load(test_data_path);
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
Y = cellfun(@(x) [x(1, train.bin_range), x(2, train.bin_range), x(3, train.bin_range)], ...
    train.histocounts, 'UniformOutput', false);
Y = cell2mat(Y);

test_Y = cellfun(@(x) [x(1, test.bin_range), x(2, test.bin_range), x(3, test.bin_range)], ...
    test.histocounts, 'UniformOutput', false);
test_Y = cell2mat(test_Y);

%% Test with train data

[pred_histo, pred_var] = GP.PredictNoChecks(train.heat_maps);

pred_error = zeros(size(train.heat_maps, 1), 1);
for i=1:size(train.heat_maps, 1)
    pred_error(i) = norm(pred_histo(i, :) - Y(i, :));
end

assert(mean(pred_error) < error_th, 'Predicted data does not match test data');
assert(mean(pred_var) < tol, 'Predicted variance is too high');

%% Test with test data

pred_histo = GP.PredictNoChecks(test.heat_maps);

pred_error = zeros(size(test.heat_maps, 1), 1);
for i=1:size(test.heat_maps, 1)
    pred_error(i) = norm(pred_histo(i, :) - test_Y(i, :));
end

assert(mean(pred_error) < error_th, 'Failed with test data');