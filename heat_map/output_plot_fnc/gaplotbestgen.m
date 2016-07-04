function [state, options, optchanged] = gaplotbestgen(options, state, flag, ...
    input_image_path, output_img_folder, num_goal)
%GAPLOTBESTGEN Plotting for GA
%   GAPLOTBESTGEN Plot the rendered image of the best heat map on each
%   iteration
persistent FIG_H N_H C_IMG IMGS
optchanged = false;

% Already showing the last image when the GA is done, so do no nothing
if strcmp(flag, 'done')
    return;
end

if state.Generation == 0 && ~isBatchMode()
    IMGS = {};
    C_IMG = zeros(num_goal, 1);
    FIG_H = cell(num_goal, 1);
    N_H = cell(num_goal, 1);
    
    for i=1:num_goal
        
        % Create a new figure
        FIG_H{i} = figure('Position', [725 + (i - 1) * 570, 500 560 420]);
        set(FIG_H{i}, 'Name', ['Best HeatMap Cam' num2str(i)]);
        
        % Add iamge forward and backward buttons to the figure
        uicontrol(FIG_H{i}, 'Style', 'pushbutton', 'String', '<<',...
            'Position', [130 20 50 20],...
            'Callback',  @(x,y) bw_10_update(x,y,i));
        
        uicontrol(FIG_H{i}, 'Style', 'pushbutton', 'String', '<',...
            'Position', [190 20 50 20],...
            'Callback',  @(x,y) bw_update(x,y,i));
        
        uicontrol(FIG_H{i}, 'Style', 'pushbutton', 'String', '>',...
            'Position', [300 20 50 20],...
            'Callback',  @(x,y) fw_update(x,y,i));
        
        uicontrol(FIG_H{i}, 'Style', 'pushbutton', 'String', '>>',...
            'Position', [360 20 50 20],...
            'Callback',  @(x,y) fw_10_update(x,y,i));
        
        N_H{i} = uicontrol(FIG_H{i}, 'Style','text',...
            'Position',[245 20 50 20],...
            'String', 'None');
    end
end

% File might not exits because it might be a cached value, in that case
% it is normally safe to assume that the previous image is still the
% best one
if(exist([input_image_path '1.tif'], 'file') == 2)
    
    % Rename the best image using the generation number
    first_g_path = [output_img_folder  'best-iter' num2str(state.Generation) ...
        '-Cam'];
    
    for i=1:num_goal
        istr = num2str(i);
        movefile([input_image_path istr '.tif'], [first_g_path istr '.tif']);
    end
    
    if isBatchMode()
        return;
    end
    
    next_idx = size(IMGS, 2) + 1;
    for i=1:num_goal
        % Read and show the image
        img = imread([first_g_path num2str(i) '.tif']);
        IMGS{i, next_idx} = img(:,:,1:3);
    end
    
else
    if isempty(IMGS) || isBatchMode()
        return;
    end
    
    % If the image does not exits and there is a previous image, copy the
    % previous one in the current one
    current_idx = size(IMGS, 2);
    for i=1:num_goal
        IMGS{i, current_idx + 1} = IMGS{i, current_idx};
    end
end

% If current image index points to the last image then update for the
% current one, i.e. do not update if the user is looking at a different
% image
for i=1:num_goal
    if(C_IMG(i) + 1 == numel(IMGS(i,:)))
        C_IMG(i) = numel(IMGS(i,:));
        common_update(i);
    else
        % Update the current image counter in the GUI
        N_H{i}.String = [num2str(C_IMG(i)) '/' num2str(numel(IMGS(i,:)))];
        drawnow;
    end
end

%% Update button callbacks
    function common_update(i)
        N_H{i}.String = [num2str(C_IMG(i)) '/' num2str(numel(IMGS(i,:)))];
        
        % Make our figure the current figure
        set(groot, 'CurrentFigure', FIG_H{i});
        imshow(IMGS{i, C_IMG(i)});
        
        drawnow; % Force a graphics update in the figure
    end

    function bw_update(~,~, i)
        
        if C_IMG(i) > 1 && ~isempty(IMGS) && numel(IMGS(i,:)) >= 1
            C_IMG(i) = C_IMG(i) - 1;
            
            common_update(i);
        end
    end

    function bw_10_update(~,~,i)
        
        if C_IMG(i) > 1 && ~isempty(IMGS) && numel(IMGS(i,:)) >= 1
            C_IMG(i) = C_IMG(i) - 10;
            if C_IMG(i) < 1
                C_IMG(i) = 1;
            end
            
            common_update(i);
        end
    end

    function fw_update(~,~,i)
        
        if ~isempty(IMGS) && C_IMG(i) < numel(IMGS(i,:)) && ...
                numel(IMGS(i,:)) > 1
            C_IMG(i) = C_IMG(i) + 1;
            
            common_update(i);
        end
    end

    function fw_10_update(~,~,i)
        
        if ~isempty(IMGS) && C_IMG(i) < numel(IMGS(i,:)) && ...
                numel(IMGS(i,:)) > 1
            
            C_IMG(i) = C_IMG(i) + 10;
            if C_IMG(i) > numel(IMGS(i,:))
                C_IMG(i) = numel(IMGS(i,:));
            end
            
            common_update(i);
        end
    end

end

