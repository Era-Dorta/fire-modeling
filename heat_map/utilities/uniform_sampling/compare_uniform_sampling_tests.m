function compare_uniform_sampling_tests(output_folder, opts)
%COMPARE_UNIFORM_SAMPLING_TESTS Plots do_uniform_sampler results
%   COMPARE_UNIFORM_SAMPLING_TESTS( OUTPUT_FOLDER, OPTS ) Given a folder
%   path OUTPUT_FOLDER and a struct OPTS with summary options of a
%   do_uniform_sampler. It plots the mean and std values for the histograms
%
%   See also do_uniform_sampler

% Convert the bin norm to percentage of the maximum norm
steps = (opts.BinNorm / opts.MaxNorm) * 100;

%% Plot the comparison
for i=1:numel(opts.color_space)
    % Load the data file
    mean_rgb = opts.MeanRGBDistance{i};
    std_rgb = opts.StdRGBDistance{i};
    
    if isBatchMode()
        fig_h = figure('Visible', 'off');
    else
        fig_h = figure('Position', [125 500 560 420]);
    end
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
    
    legend([opts.color_space{i}(1) ' Channel'], [opts.color_space{i}(2) ' Channel'], ...
        [opts.color_space{i}(3) ' Channel'], 'Location', 'best');
    
    hold off;
    
    %% Save the figure
    figurePath = fullfile(output_folder, ['uniform_sampler_' opts.color_space{i}]);
    saveas(fig_h, figurePath, 'svg');
    print(fig_h, figurePath, '-dtiff');
end
end

