function compare_uniform_sampling_tests(output_folder, opts)
%COMPARE_UNIFORM_SAMPLING_TESTS Plots do_uniform_sampler results
%   COMPARE_UNIFORM_SAMPLING_TESTS( OUTPUT_FOLDER, OPTS ) Given a folder
%   path OUTPUT_FOLDER and a struct OPTS with summary options of a
%   do_uniform_sampler. It plots the mean and std values for the histograms
%
%   See also do_uniform_sampler

% Load the data file
mean_rgb = opts.MeanRGBDistance;
std_rgb = opts.StdRGBDistance;

% Convert the bin norm to percentage of the maximum norm
steps = (opts.BinNorm / opts.MaxNorm) * 100;

%% Plot the comparison
fig_h = figure;
hold on;

% Plot the mean value at regular intervals with error bars for the standard
% deviation of each value
errorbar(steps, mean_rgb(:,1), std_rgb(:,1), '-rx');
errorbar(steps, mean_rgb(:,2), std_rgb(:,2), '-gx');
errorbar(steps, mean_rgb(:,3), std_rgb(:,3), '-bx');

xlabel('Step size (% of max step size)');
ylabel('Histogram Distance');

% Change the regular intervals for the actual step size
xlim([0,100]);

legend('Red Channel', 'Green Channel', 'Blue Channel', 'Location', 'best');

hold off;

%% Save the figure
figurePath = fullfile(output_folder, 'uniform_sampler');
saveas(fig_h, figurePath, 'svg');
print(fig_h, figurePath, '-dtiff');
end

