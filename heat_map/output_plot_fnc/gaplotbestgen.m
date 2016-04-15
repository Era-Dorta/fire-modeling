function [state, options, optchanged] = gaplotbestgen(options, state, flag, ...
    input_image, output_img_folder)
%GAPLOTBESTGEN Plotting for GA
%   GAPLOTBESTGEN Plot the rendered image of the best heat map on each
%   iteration
persistent FIG_H
optchanged = false;

if state.Generation == 0
    % Create a new figure
    if isBatchMode()
        FIG_H = figure('Visible', 'off');
    else
        FIG_H = figure('Position', [806 514 560 420]);
    end
    set(FIG_H, 'Name', 'Best HeatMap');
end

first_g_path = [output_img_folder  'best-' num2str(state.Generation) '.tif'];

% File might not exits because it might be a cached value, in that case
% it is normally safe to assume that the previous image is still the
% best one
if(exist(input_image, 'file') == 2)
    movefile(input_image, first_g_path);
    
    % Make our figure the current figure
    set(groot, 'CurrentFigure', FIG_H);
    
    if ~isBatchMode()
        img = imread(first_g_path);
        imshow(img(:,:,1:3));
        drawnow; % Force a graphics update in the figure
    end
end

end

