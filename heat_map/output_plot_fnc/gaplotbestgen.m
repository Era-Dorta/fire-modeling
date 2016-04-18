function [state, options, optchanged] = gaplotbestgen(options, state, flag, ...
    input_image, output_img_folder)
%GAPLOTBESTGEN Plotting for GA
%   GAPLOTBESTGEN Plot the rendered image of the best heat map on each
%   iteration
persistent FIG_H N_H C_IMG IMGS
optchanged = false;

if state.Generation == 0
    if isBatchMode()
        return;
    end
    
    IMGS = {};
    C_IMG = 0;
    
    % Create a new figure
    FIG_H = figure('Position', [806 514 560 420]);
    set(FIG_H, 'Name', 'Best HeatMap');
    
    % Add iamge forward and backward buttons to the figure
    uicontrol(FIG_H, 'Style', 'pushbutton', 'String', '<<',...
        'Position', [130 20 50 20],...
        'Callback',  @bw_10_update);
    
    uicontrol(FIG_H, 'Style', 'pushbutton', 'String', '<',...
        'Position', [190 20 50 20],...
        'Callback',  @bw_update);
    
    uicontrol(FIG_H, 'Style', 'pushbutton', 'String', '>',...
        'Position', [300 20 50 20],...
        'Callback',  @fw_update);
    
    uicontrol(FIG_H, 'Style', 'pushbutton', 'String', '>>',...
        'Position', [360 20 50 20],...
        'Callback',  @fw_10_update);
    
    N_H = uicontrol(FIG_H, 'Style','text',...
        'Position',[245 20 50 20],...
        'String', 'None');
end

% File might not exits because it might be a cached value, in that case
% it is normally safe to assume that the previous image is still the
% best one
if(exist(input_image, 'file') == 2)
    
    % Rename the best image using the generation number
    first_g_path = [output_img_folder  'best-' num2str(state.Generation) '.tif'];
    
    movefile(input_image, first_g_path);
    
    if isBatchMode()
        return;
    end
    
    
    % Read and show the image
    img = imread(first_g_path);
    IMGS{end + 1} = img(:,:,1:3);
    
    % Make our figure the current figure
    set(groot, 'CurrentFigure', FIG_H);
    
    imshow(img(:,:,1:3));
    drawnow; % Force a graphics update in the figure
    
else
    if isBatchMode()
        return;
    end
    
    % If the image does not exits copy the previous one
    if(numel(IMGS) >= 1)
        IMGS{end + 1} = IMGS{end};
    end
end

% Update the current image counter in the GUI
N_H.String = [num2str(state.Generation) '/' num2str(numel(IMGS) - 1)];
C_IMG = state.Generation + 1;

%% Update button callbacks
    function common_update()
        N_H.String = [num2str(C_IMG - 1) '/' num2str(numel(IMGS) - 1)];
        
        % Make our figure the current figure
        set(groot, 'CurrentFigure', FIG_H);
        imshow(IMGS{C_IMG});
        
        drawnow; % Force a graphics update in the figure
    end

    function bw_update(~,~)
        
        if C_IMG > 1 && numel(IMGS) >= 1
            C_IMG = C_IMG - 1;
            
            common_update();
        end
    end

    function bw_10_update(~,~)
        
        if C_IMG > 1 && numel(IMGS) >= 1
            C_IMG = C_IMG - 10;
            if C_IMG < 1
                C_IMG = 1;
            end
            
            common_update();
        end
    end

    function fw_update(~,~)
        
        if C_IMG < numel(IMGS) && numel(IMGS) > 1
            C_IMG = C_IMG + 1;
            
            common_update();
        end
    end

    function fw_10_update(~,~)
        
        if C_IMG < numel(IMGS) && numel(IMGS) > 1
            
            C_IMG = C_IMG + 10;
            if C_IMG > numel(IMGS)
                C_IMG = numel(IMGS);
            end
            
            common_update();
        end
    end

end

