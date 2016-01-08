function [state, options, optchanged] = gaplotbestcustom(options, state, flag, figurePath)
% Plotting function for the Ga solver

% Ugly hack to allow for better plotting, as we cannot change the output of
% the function
persistent GAPLOTBEST GAPLOTMEAN MAXERROR

optchanged = false;

% Create/Get the handle for the figure
h = figure(1);

% If in batch mode no need to actually draw
if isBatchMode()
    set(h, 'Visible', 'off');
end

% The plot function is called when the algorithm is finished, save the
% image here
if strcmp(flag, 'done')
    if isBatchMode()
        print(h, figurePath, '-dtiff');
        saveas(h, figurePath, 'fig');
        
        % Matlab older than 2015 does not support svg conversion, use a
        % custom function to save the file, the custom function is slower
        % and produces significantly larger files than the native one
        matversion = version('-release');
        custom_svg = str2double(matversion(1:4)) < 2015;
        
        if custom_svg
            plot2svg([figurePath '.svg'], h);
        else
            saveas(h, figurePath, 'svg')
        end
    end
    return;
end

if state.Generation == 0
    % Clear everything on the first draw
    clf(h);
    
    % If in batch mode no need to actually draw
    if isBatchMode()
        set(h, 'Visible', 'off');
    end
    
    set(h, 'Name', 'Error function');
    xlabel('Generation')
    ylabel('Error')
    set(gca,'xlim', [0, 1]);
    
    % For the initial population the state.Best variable is empty, so
    % compute the values from the Score
    GAPLOTBEST = min(state.Score);
    GAPLOTMEAN = [];
    MAXERROR = max(state.Score);
else
    GAPLOTBEST = [GAPLOTBEST, state.Best(end)];
    set(gca,'xlim', [0, state.Generation]);
    c_error = max(state.Score);
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
GAPLOTMEAN = [GAPLOTMEAN, mean(state.Score)];
plot(0:state.Generation, GAPLOTMEAN, '-go');

legend('Best', 'Mean');
hold off;
end
