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
step_size = opts.StepSize;

% Step size is edges for a histogram, convert to a new vector with the
% mean bin value
max_step_size = step_size(end);

step_size = step_size + mean(step_size(1:2));
step_size = step_size(1:end-1);

num_steps = numel(step_size);

% Convert the step size to percentage of the maximum step size
step_size = (step_size / max_step_size) * 100;

%% Plot the comparison

fig_h = figure;
hold on;

% Plot the mean value at regular intervals with error bars for the standard
% deviation of each value
errorbar(1:num_steps, mean_rgb(:,1), std_rgb(:,1), '-rx');
errorbar(1:num_steps, mean_rgb(:,2), std_rgb(:,2), '-gx');
errorbar(1:num_steps, mean_rgb(:,3), std_rgb(:,3), '-bx');

xlabel('Step size (% of max step size)');
ylabel('Histogram Distance');

% Change the regular intervals for the actual step size
set(gca,'XTick', 1:num_steps);
set(gca,'xticklabel', strsplit(num2str(step_size)));

legend('Red Channel', 'Green Channel', 'Blue Channel', 'Location', 'northwest');

hold off;

%% Save the figure
figurePath = fullfile(output_folder, 'uniform_sampler');
saveas(fig_h, figurePath, 'svg');
print(fig_h, figurePath, '-dtiff');
end

