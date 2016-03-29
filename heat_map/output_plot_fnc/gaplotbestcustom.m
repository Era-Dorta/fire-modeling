function [state, options, optchanged] = gaplotbestcustom(options, state, flag, figurePath)
% Plotting function for the Ga solver

% Ugly hack to allow for better plotting, as we cannot change the output of
% the function
persistent GAPLOTBEST GAPLOTMEAN MAXERROR FIG_H

optchanged = false;

% The plot function is called when the algorithm is finished, save the
% image here
if strcmp(flag, 'done')
    % Make our figure the current figure
    set(groot, 'CurrentFigure', FIG_H);
    
    legend('Best', 'Mean');
    
    if isBatchMode()
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
    end
    return;
end

inf_error_idx = state.Score == realmax;

if state.Generation == 0
    % Create a new figure
    if isBatchMode()
        FIG_H = figure('Visible', 'off');
    else
        FIG_H = figure;
    end
    
    set(FIG_H, 'Name', 'Error function');
    xlabel('Generation')
    ylabel('Error')
    set(gca,'xlim', [0, 1]);
    
    % For the initial population the state.Best variable is empty, so
    % compute the values from the Score
    GAPLOTBEST = min(state.Score);
    GAPLOTMEAN = [];
    MAXERROR = max(state.Score(~inf_error_idx));
    if(isempty(MAXERROR))
        MAXERROR = 1;
    end
else
    % Make our figure the current figure
    set(groot, 'CurrentFigure', FIG_H);
    
    GAPLOTBEST = [GAPLOTBEST, state.Best(end)];
    set(gca,'xlim', [0, state.Generation]);
    c_error = max(state.Score(~inf_error_idx));
    if c_error > MAXERROR
        MAXERROR = c_error;
    end
end

% Y axis from max error to 0
set(gca,'ylim', [0, MAXERROR]);

hold on;

% Plot the best error
plot(0:state.Generation, GAPLOTBEST, '-rx');

% Plot the mean error
GAPLOTMEAN = [GAPLOTMEAN, mean(state.Score(~inf_error_idx))];
plot(0:state.Generation, GAPLOTMEAN, '-go');
hold off;
end
