function compare_qmc_tests( data_folder)
%COMPARE_QMC_TESTS Compares qmc_sampler_* results
%   COMPARE_QMC_TESTS( DATA_FOLDER ) Given a folder path DATA_FOLDER
%   which contains a series of qmc_sampler_I output folders of the
%   qmc_sampler output where I is a natural number. It plots the mean and
%   std values for the histograms.
%
%   See also do_quasi_mc_sampler

% Get folder contents
hm_data_folders = dir(data_folder);
hm_data_folders = {hm_data_folders.name};

% Remove anything that is not hm_search_[digit]
to_del_idx = [];
for i=1:numel(hm_data_folders)
    if isempty(regexp(hm_data_folders{i},'qmc_sampler_[0-9]+', 'ONCE'))
        to_del_idx = [to_del_idx; i];
    end
end
hm_data_folders(to_del_idx) = [];

% Initialize variables
num_hm = numel(hm_data_folders);

mean_rgb = zeros(num_hm, 3);
std_rgb = zeros(num_hm, 3);
step_size = zeros(num_hm, 1);

% Read the mean, std and sample divisions for each run
for i=1:num_hm
    % Build path of current hm_search
    hm_data_folder = fullfile(data_folder, hm_data_folders{i});
    
    % Load the data file
    opts = load(fullfile(hm_data_folder, 'summary_file.mat'));
    opts = opts.summary_data;
    
    mean_rgb(i,:) = opts.MeanRGBDistance;
    std_rgb(i,:) = opts.StdRGBDistance;
    step_size(i) = opts.StepSize;
    
end

% Convert the step size to percentage of the maximum step size
max_step_size = zeros(opts.HeatMapNumVariables, 1) + opts.UB;
max_step_size = max_step_size - opts.LB;
max_step_size = norm(max_step_size);

step_size = (step_size / max_step_size) * 100;

%% Plot the comparison

fig_h = figure;
hold on;

% Plot the mean value at regular intervals with error bars for the standard
% deviation of each value
errorbar(1:num_hm, mean_rgb(:,1), std_rgb(:,1), '-rx');
errorbar(1:num_hm, mean_rgb(:,2), std_rgb(:,2), '-gx');
errorbar(1:num_hm, mean_rgb(:,3), std_rgb(:,3), '-bx');

xlabel('Step size (% of max step size)'); 
ylabel('Histogram Distance');

% Change the regular intervals for the actual step size
set(gca,'XTick', 1:num_hm);
set(gca,'xticklabel', num2str(step_size));

legend('Red Channel', 'Green Channel', 'Blue Channel', 'Location', 'northwest');

hold off;

%% Save the figure
figurePath = fullfile(data_folder, 'qmc-comparison');
saveas(fig_h, figurePath, 'svg');
print(fig_h, figurePath, '-dtiff');
end

