function compare_distance_tests( data_folder )
%COMPARE_DISTANCE_TESTS Compares hm_search_* results
%   COMPARE_DISTANCE_TESTS( DATA_FOLDER ) Given a folder path DATA_FOLDER
%   which contains a series of hm_search_I where I goes from 1 to N of
%   output folders from heatMapReconstruction. It computes the MSE error
%   with the goal image/s, plots the result and saves the data in the
%   folder.
%
%   See also heatMapReconstruction

dist_foo_str = {};

% Read the optimized images for each solver run
dir_num = 1;
hm_data_folder = fullfile(data_folder, 'hm_search_1');
mse_error = [];
while(exist(hm_data_folder, 'dir') == 7)
    
    % Load the data file
    opts = load(fullfile(hm_data_folder, 'summary_file.mat'));
    opts = opts.summary_data;
    num_goal = numel(opts.goal_img_path);
    
    % Get the distance function name
    dist_foo_str{dir_num} = func2str(opts.dist_foo);
    
    % Read all the optimized images
    cam_num = 1;
    img = cell(num_goal, 1);
    for j=1:num_goal
        img_path = fullfile(fullfile(hm_data_folder, ['optimized-Cam' ...
            num2str(j) '.tif']));
        
        if(exist(img_path, 'file') ~= 2)
            error(['Missing file ' img_path]);
        end
        
        img{cam_num} = imread(img_path);
        img{cam_num} = img{cam_num}(:,:,1:3);
    end
    
    % Read the goal image, it should be the same for all of them
    [ goal_img, goal_mask, img_mask] = readGoalAndMask( opts.goal_img_path, ...
        opts.mask_img_path, opts.goal_mask_img_path, false);
    
    % Get the goal without background
    [goal_img, ~, ~] = preprocess_images(goal_img, goal_mask, img_mask, ...
        opts.bin_mask_threshold, false);
    
    % As we are comparing with MSE and we assume this is synthetic data use
    % a all ones mask
    for j=1:num_goal
        goal_mask{j} = true(size(goal_mask{j}));
        img_mask{j} = true(size(img_mask{j}));
    end
    
    mse_error = [mse_error, MSE(goal_img, img, goal_mask, img_mask)];
    
    dir_num = dir_num + 1;
    hm_data_folder = fullfile(data_folder, ['hm_search_' num2str(dir_num)]);
end

%% Plot the comparison
% Scape the underscores to avoid substript in the legend
dist_foo_str1 = strrep(dist_foo_str, '_', '\_');

fig_h = figure;
hold on;

% Plot each one separately to be able to use legend
colors = {'b' , 'r' , 'g', 'c' , 'm' , 'y' , 'k' , 'w'};
for i=1:numel(mse_error)
    bar(i, mse_error(i), colors{i});
end
set(gca,'ylim', [0, 1]); % Maximum error is 1
legend(dist_foo_str1);
hold off;

%% Save the output
% Save the data file, do not overwrite previous results
data_path = fullfile(data_folder, 'data.txt');
if(exist(data_path, 'file') == 2)
    error(['File ' data_path ' exits, avoiding overwrite.']);
end

fileId = fopen(data_path, 'w');

if(fileId ~= -1)
    closeFileObj = onCleanup(@() fclose(fileId));
else
    error(['Cannot open file ' data_path]);
end

% Put the data together in a cell string
data_str = cell(2, numel(mse_error));
for i=1:numel(mse_error)
    data_str{1, i} = dist_foo_str{i};
    data_str{2, i} = num2str(mse_error(i), '%e');
end

fprintf(fileId, 'Distance comparison\nError function, MSE error\n');
fprintf(fileId, '%s, %s\n', data_str{:});

% Save the figure
figurePath = fullfile(data_folder, 'mse-comparison');
saveas(fig_h, figurePath, 'svg');
print(fig_h, figurePath, '-dtiff');
end

