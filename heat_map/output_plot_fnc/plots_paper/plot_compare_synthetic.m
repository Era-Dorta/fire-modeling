function plot_compare_synthetic()
%PLOT_COMPARE_SYNTHETIC Summary of this function goes here
%   Detailed explanation goes here

% This are the data files from
% test111_no_background/transfer-method-comparison-synthetic/*
folder_list = {'cmaes_random_init', 'ga_random_init', 'sa_random_init', ...
    'simplex_random_init'};
color_list = {'b', 'y', 'g', 'r'};
legend_list = cell(numel(folder_list), 1);

error_arr = zeros(numel(folder_list), 1);
for i=1:numel(folder_list)
    data = load(fullfile('optimization_synthetic', folder_list{i}, ...
        'summary_file.mat'));
    error_arr(i) = data.summary_data.ImageError;
    legend_list{i} = strsplit(folder_list{i}, '_');
    legend_list{i} = legend_list{i}{1};
end

figure;
bar(1, error_arr(1), color_list{1});
hold on;
for i=2:numel(folder_list)
    bar(i, error_arr(i), color_list{i});
end
legend(legend_list, 'Location','northwest');
set(gca,'xtick',[])

[current_folder, ~, ~] = fileparts(mfilename('fullpath'));
save_path = fullfile(current_folder, 'optimization_synthetic', 'error_fig');
saveas(gcf,save_path,'epsc');
end

