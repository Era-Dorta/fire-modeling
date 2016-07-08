function background_extraction_gui(default_dir)
% BACKGROUND_EXTRACTION_GUI Background extraction with trimap
% BACKGROUND_EXTRACTION_GUI() Opens a figure that allows the user to load
% an image and trimap. Perform background extraction and save the result.
% A slider is provided to change the alpha threshold.
%
% BACKGROUND_EXTRACTION_GUI(DEFAULT_DIR) File loading and saving dialogs
% will be initialized to the path indicated in DEFAULT_DIR.

if(nargin == 0)
    default_dir = pwd;
end

img = [];
trimap = [];
alpha = [];
img_subs = [];
bg_only = [];
img_mask = [];
bin_mask_threshold = 0.1;

% Create a figure with controllers to load and save the images.
fig_h = figure('Position', [680   554   860   420]);
uicontrol(fig_h, 'Style', 'pushbutton', 'String', 'Load Img', ...
    'Position', [10 5 100 20], 'Callback', @imgLoadCallback);

uicontrol(fig_h, 'Style', 'pushbutton', 'String', 'Load TriMap',...
    'Position', [110 5 100 20], 'Callback', @trimapLoadCallback);

uicontrol(fig_h, 'Style', 'pushbutton', 'String', 'Save Mask',...
    'Position', [210 5 100 20], 'Callback', @maskSaveCallback);

uicontrol(fig_h, 'Style', 'pushbutton', 'String', 'Save Background',...
    'Position', [310 5 100 20], 'Callback', @bgSaveCallback);

uicontrol(fig_h, 'Style', 'pushbutton', 'String', 'Save Foreground',...
    'Position', [410 5 100 20], 'Callback', @fgSaveCallback);

uicontrol(fig_h, 'Style', 'pushbutton', 'String', 'Save Alpha',...
    'Position', [510 5 100 20], 'Callback', @alphaSaveCallback);

slider_ui = uicontrol(fig_h, 'Style', 'slider', 'Value', bin_mask_threshold, ...
    'Position', [610 5 240 20], 'Callback', @thresholdCallback);

    function imgLoadCallback(~,~)
        [in_img_path, img_dir] = uigetfile(fullfile(default_dir, '*.png;*.tif;*.jpg'));
        if in_img_path == 0
            return;
        end
        default_dir = img_dir;
        in_img_path = fullfile(img_dir, in_img_path);
        img = imread(in_img_path);
        if(size(img, 3) > 3)
            img = img(:,:,1:3);
        end
        
        set(groot, 'CurrentFigure', fig_h);
        
        % Plot the input image
        subtightplot(2,2,1);  imshow(img);
        title('Input Image');
        drawnow;
        
        compute_extraction();
    end

    function trimapLoadCallback(~,~)
        [trimap_path, img_dir] = uigetfile(fullfile(default_dir, '*.png;*.tif;*.jpg'));
        if trimap_path == 0
            return;
        end
        default_dir = img_dir;
        trimap_path = fullfile(img_dir, trimap_path);
        trimap_ori = imread(trimap_path);
        if(size(trimap_ori, 3) > 3)
            trimap_ori = trimap_ori(:,:,1:3);
        end
        
        if size(trimap_ori, 3) > 1 && ~islogical(trimap_ori)
            trimap_ori = rgb2gray(trimap_ori);
        end
        
        % 0 is the tripmap are known background and 255 are know foreground
        % Conver to background -1, foreground 1
        trimap = zeros(size(trimap_ori,1), size(trimap_ori,2));
        fore = (trimap_ori == 255);
        back = (trimap_ori == 0);
        
        trimap(fore(:,:,1)) = 1;
        trimap(back(:,:,1)) = -1;
        
        % Show with white, grey, black
        trimap_show = trimap;
        trimap_show(trimap == 0) = 0.5;
        trimap_show(trimap == -1) = 0;
        
        set(groot, 'CurrentFigure', fig_h);
        subtightplot(2,2,2); imshow(trimap_show);
        title('Image trimap');
        drawnow;
        compute_extraction();
    end

    function maskSaveCallback(~,~)
        if(~isempty(img_mask))
            [out_img_path, img_dir] = uiputfile(fullfile(default_dir, '*.png;*.tif;*.jpg'));
            if out_img_path == 0
                return;
            end
            default_dir = img_dir;
            out_img_path = fullfile(img_dir, out_img_path);
            imwrite(img_mask, out_img_path);
        end
    end

    function bgSaveCallback(~,~)
        if(~isempty(bg_only))
            [out_img_path, img_dir] = uiputfile(fullfile(default_dir, '*.png;*.tif;*.jpg'));
            if out_img_path == 0
                return;
            end
            default_dir = img_dir;
            out_img_path = fullfile(img_dir, out_img_path);
            imwrite(bg_only, out_img_path);
        end
    end

    function fgSaveCallback(~,~)
        if(~isempty(img_subs))
            [out_img_path, img_dir] = uiputfile(fullfile(default_dir, '*.png;*.tif;*.jpg'));
            if out_img_path == 0
                return;
            end
            default_dir = img_dir;
            out_img_path = fullfile(img_dir, out_img_path);
            imwrite(img_subs, out_img_path);
        end
    end

    function alphaSaveCallback(~,~)
        if(~isempty(alpha))
            [out_img_path, img_dir] = uiputfile(fullfile(default_dir, '*.png;*.tif;*.jpg'));
            if out_img_path == 0
                return;
            end
            default_dir = img_dir;
            out_img_path = fullfile(img_dir, out_img_path);
            imwrite(alpha, out_img_path);
        end
    end

    function thresholdCallback(hObject,~)
        bin_mask_threshold = hObject.Value;
        
        if(~isempty(alpha))
            img_mask = alpha > bin_mask_threshold;
            
            set(groot, 'CurrentFigure', fig_h);
            
            subtightplot(2,2,3); imshow(img_mask);
            title('Binary mask');
            drawnow;
        end
    end

    function compute_extraction()
        if(~isempty(img) && ~isempty(trimap))
            alpha = learningBasedMatting(img, trimap);
            
            % Get the new image without the background
            img_subs = uint8(bsxfun(@times, double(img), alpha));
            
            % Get the background
            bg_only = uint8(bsxfun(@times, double(img), 1 - alpha));
            
            set(groot, 'CurrentFigure', fig_h);
            subtightplot(2,2,4); imshow(img_subs);
            title('No Background');
            drawnow;
            
            % Compute the logical mask
            thresholdCallback(slider_ui,[]);
        end
    end

end

