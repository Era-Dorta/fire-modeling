function compare_distance_tests( data_folder )
%COMPARE_DISTANCE_TESTS Compares hm_search_* results
%   COMPARE_DISTANCE_TESTS( DATA_FOLDER ) Given a folder path DATA_FOLDER
%   which contains a series of hm_search_I where I goes from 1 to N of
%   output folders from heatMapReconstruction. It computes the MSE error
%   with the goal image/s, plots the result and saves the data in the
%   folder.
%
%   See also heatMapReconstruction

% Get folder contents
hm_data_folders = dir(data_folder);
hm_data_folders = {hm_data_folders.name};

% Remove anything that is not hm_search_[digit]
to_del_idx = [];
for i=1:numel(hm_data_folders)
    if isempty(regexp(hm_data_folders{i},'hm_search_[0-9]+', 'ONCE'))
        to_del_idx = [to_del_idx; i];
    end
end
hm_data_folders(to_del_idx) = [];

% Initialize variables
num_hm = numel(hm_data_folders);
dist_foo_map = containers.Map();
pop_map = containers.Map();

% Keys in order of appeareance
dist_foo_map_keys = {};
pop_map_keys = {};

% Rows for each distance sample, columns for each distance type
mse_error = [];

% Read the optimized images for each solver run
for i=1:num_hm
    % Build path of current hm_search
    hm_data_folder = fullfile(data_folder, hm_data_folders{i});
    
    % Load the data file
    opts = load(fullfile(hm_data_folder, 'summary_file.mat'));
    opts_solver = opts.options.options;
    opts = opts.summary_data;
    num_goal = numel(opts.goal_img_path);
    
    % Get the index for the distance function name
    dist_foo_name = func2str(opts.dist_foo);
    if isKey(dist_foo_map, dist_foo_name)
        dist_idx = dist_foo_map(dist_foo_name);
    else
        dist_idx = dist_foo_map.Count + 1;
        dist_foo_map(dist_foo_name) = dist_idx;
        dist_foo_map_keys{end + 1} = dist_foo_name;
    end
    
    % Get the index for the population size
    popSizeStr = num2str(opts_solver.PopulationSize);
    if isKey(pop_map, popSizeStr)
        pop_idx = pop_map(popSizeStr);
    else
        pop_idx = pop_map.Count + 1;
        pop_map(popSizeStr) = pop_idx;
        pop_map_keys{end + 1} = popSizeStr;
    end
    
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
    
    % Read the preprocessed goal image, it should be the same for all of
    % them
    goal_img = cell(1, num_goal);
    preprocessed_path = fullfile(hm_data_folder, 'preprocessed_input_images');
    for j=1:num_goal
        img_path = fullfile(preprocessed_path,['Goal-Cam' num2str(j) '.tif']);
        
        if(exist(img_path, 'file') ~= 2)
            error(['Missing file ' img_path]);
        end
        
        goal_img{j} = imread(img_path);
    end
    
    % As we are comparing with MSE and we assume this is synthetic data use
    % mask with all ones, to use the full image
    goal_mask = cell(1, num_goal);
    img_mask = cell(1, num_goal);
    for j=1:num_goal
        goal_mask{j} = true(size(goal_img{j}, 1), size(goal_img{j}, 2));
        img_mask{j} = true(size(img{j}, 1), size(img{j}, 2));
    end
    
    mse_error(pop_idx, dist_idx) = MSE(goal_img, img, goal_mask, img_mask);
end

%% Plot the comparison
% Do not use the .keys in plotting as they are not output in order
% Scape the underscores to avoid substript in the legend
dist_foo_map_keys_u = strrep(dist_foo_map_keys, '_', '\_');

fig_h = figure;
hold on;

if size(mse_error, 1) == 1
    % Plot each one separately to be able to use legend and colors
    colors = {'b' , 'r' , 'g', 'c' , 'm' , 'y' , 'k' , 'w'};
    for i=1:numel(mse_error)
        bar(i, mse_error(i), colors{i});
    end
else
    bar(mse_error);
end

xlabel('Population');
ylabel('MSE Error');

% X-axis use the population number
set(gca,'XTick', 1:size(mse_error, 2));
set(gca,'xticklabel', pop_map_keys);

set(gca,'ylim', [0, 1]); % Maximum error is 1
legend(dist_foo_map_keys_u);
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
data_str = cell(3, dist_foo_map.Count * pop_map.Count);
k = 1;
for i=1:pop_map.Count
    for j=1:dist_foo_map.Count
        data_str{1, k} = dist_foo_map_keys{j};
        data_str{2, k} = pop_map_keys{i};
        
        imse = pop_map(pop_map_keys{i});
        jmse = dist_foo_map(dist_foo_map_keys{j});
        data_str{3, k} = num2str(mse_error(imse,jmse), '%e');
        k = k + 1;
    end
end

fprintf(fileId, 'Distance comparison\nError function, Population, MSE error\n');
fprintf(fileId, '%s, %s, %s\n', data_str{:});

% Save the figure
figurePath = fullfile(data_folder, 'mse-comparison');
saveas(fig_h, figurePath, 'svg');
print(fig_h, figurePath, '-dtiff');
end

