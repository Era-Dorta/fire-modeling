function [stop] = gradploterror(~, optimValues, state, figurePath)
%GRADPLOTBESTGEN Plotting for Gradient solver
%   GRADPLOTBESTGEN Plot the rendered image of the best heat map on each
%   iteration
stop = false;

if strcmp(state, 'init')
    return;
end

% Ugly hack to allow for better plotting, as we cannot change the output of
% the function
persistent ERROR ERROR_SUB X_VAL FIG_H SAMPLE_RATE

% The plot function is called when the algorithm is finished, save the
% image here
if strcmp(state, 'done')
    % Make our figure the current figure
    set(groot, 'CurrentFigure', FIG_H);
    
    print(FIG_H, figurePath, '-dtiff');
    saveas(FIG_H, figurePath, 'fig');
    
    % Matlab older than 2015 does not support svg conversion, use a
    % custom function to save the file, the custom function is slower
    % and produces significantly larger files than the native one
    matversion = version('-release');
    custom_svg = str2double(matversion(1:4)) < 2015;
    
    if custom_svg
        plot2svg([figurePath '.svg'], FIG_H);
    else
        saveas(FIG_H, figurePath, 'svg')
    end
    
    return;
end

if optimValues.iteration == 0
    % Create a new figure
    if isBatchMode()
        FIG_H = figure('Visible', 'off');
    else
        FIG_H = figure('Position', [125 500 560 420]);
    end
    
    set(FIG_H, 'Name', 'Error function');
    xlabel('Iteration')
    ylabel('Error')
    set(gca,'xlim', [0, 1]);
    
    ERROR = optimValues.fval;
    
    ERROR_SUB = ERROR;
    X_VAL = 0:optimValues.iteration;
    
    SAMPLE_RATE = 1;
else
    % Make our figure the current figure
    set(groot, 'CurrentFigure', FIG_H);
    
    ERROR = [ERROR, optimValues.fval];
    
    if numel(ERROR) <= 100
        ERROR_SUB = ERROR;
        X_VAL = 0:optimValues.iteration;
    else
        % Downsample when the number of points is too large, ideally it
        % would be / 100, for max of 100 points, but due to rounding we
        % use a lower value
        new_sample_rate = round(numel(ERROR) / 75);
        
        if new_sample_rate ~= SAMPLE_RATE
            % Clear the plot when the sampling rate changes
            cla(gca);
            SAMPLE_RATE = new_sample_rate;
        end
        
        % Down sample the data
        ERROR_SUB = downsample(ERROR, SAMPLE_RATE);
        X_VAL = downsample(0:optimValues.iteration, SAMPLE_RATE);
    end
    
    set(gca,'xlim', [0, optimValues.iteration]);
end

hold on;

% Plot the best error
plot(X_VAL, ERROR_SUB, '-rx');

% Legend is a costly plotting function, do it just once
if optimValues.iteration == 0
    % It has to be called after at least one plot(...)
    legend('Error');
    
    ylim1 = get(gca, 'ylim');
    set(gca,'ylim', [0, ylim1(2)]);
end

hold off;

drawnow; % Force a graphics update in the figure

end

