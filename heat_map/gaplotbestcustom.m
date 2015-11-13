function [ state ] = gaplotbestcustom(options, state, flag, figurePath)
% Ugly hack to allow for better plotting, as we cannot change the output of
% the function
persistent GAPLOTBEST GAPLOTMEAN MAXERROR

% The plot function is called when the algorithm finished too, we already
% plotted everything, so exit here
if strcmp(flag, 'done')
    return;
end

% Create/Get the handle for the figure
h = figure(1);

if state.Generation == 0
    % Clear everything on the first draw
    clf(h);
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
    GAPLOTBEST =  [GAPLOTBEST, state.Best(end)];
    set(gca,'xlim', [0, state.Generation]);
    c_error = max(state.Score);
    if c_error > MAXERROR
        MAXERROR = c_error;
    end
end

% Generation x axis with in integers
set(gca,'xtick', 0:state.Generation);

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
