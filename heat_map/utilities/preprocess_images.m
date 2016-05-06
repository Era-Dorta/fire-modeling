function [ goal_imgs, goal_mask_imgs, mask_imgs, mask_threshold ] = preprocess_images( ...
    goal_imgs, goal_mask_imgs, mask_imgs, figurePath)
%[ GOAL_IMGS, GOAL_MASK_IMGS, MASK_IMGS, MASK_THRESHOLD ] = PREPROCESS_IMAGES(
%   GOAL_IMGS, GOAL_MASK_IMGS, MASK_IMGS, FIGUREPATH) Background
%   subtraction of GOAL_IMGS using GOAL_MASK_IMGS interpreted as a trimap.
%   GOAL_MASK_IMGS and MASK_IMGS are converted from to gray mask to logical
%   masks. Results are saved in FIGUREPATH.

n_row = 2;
n_col = 3;

% By default ignore any pixel that is less than 10% foreground
mask_threshold = zeros(numel(goal_imgs), 1) + 1e-1;

mask_imgs_ori = mask_imgs;
alpha = cell(numel(goal_imgs), 1);

total_str = num2str(numel(goal_imgs));

save_path = cell(numel(goal_imgs), 1);
slider_ui = gobjects(numel(goal_imgs), 1);
button_ui = gobjects(numel(goal_imgs), 1);
text_ui = gobjects(numel(goal_imgs), 1);
fig_h = gobjects(numel(goal_imgs), 1);

for i=1:numel(goal_imgs)
    
    %% Prepare the data for alpha matting
    istr = num2str(i);
    save_path{i} = [figurePath istr '.tif'];
    
    disp(['Preprocessing input images and masks ' istr '/' total_str]);
    
    % Conver the scrible mask image to a trimap image
    mask = zeros(size(goal_mask_imgs{i},1), size(goal_mask_imgs{i},2));
    fore = (goal_mask_imgs{i} == 255);
    back = (goal_mask_imgs{i} == 0);
    
    mask(fore(:,:,1)) = 1;
    mask(back(:,:,1)) = -1;
    
    % Plot the goal image and the trimap
    c_fig = 1;
    if isBatchMode()
        fig_h(i) = figure('Visible', 'off');
    else
        fig_h(i) = figure();
        text_ui(i) = uicontrol('Style','text', 'Position',[5 5 150 20],...
            'String', 'Processing ...');
        slider_ui(i) = uicontrol(fig_h(i), 'Style', 'slider', 'Value', mask_threshold(i), ...
            'Position', [165 5 250 20], 'Enable', 'off');
        button_ui(i) = uicontrol(fig_h(i), 'Style', 'pushbutton', 'String', ...
            'Continue', 'Position', [455 5 70 20], 'Enable', 'off');
    end
    fig_h(i).Name = ['Goal and mask images ' istr];
    
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(goal_imgs{i});
    title('Original goal image');
    
    % To be able to show the trimap, convert all the 0 to 0.5 (unknown) and
    % all the -1 to 0 (background)
    mask_show = mask;
    mask_show(mask == 0) = 0.5;
    mask_show(mask == -1) = 0;
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(mask_show);
    title('Original goal trimap');
    
    drawnow;
    
    %% Compute the alpha matte
    alpha{i} = learningBasedMatting(goal_imgs{i}, mask);
    
    % Get the new goal image without the background
    goal_imgs{i}(:,:,1) = uint8(double(goal_imgs{i}(:,:,1)) .* alpha{i});
    goal_imgs{i}(:,:,2) = uint8(double(goal_imgs{i}(:,:,2)) .* alpha{i});
    goal_imgs{i}(:,:,3) = uint8(double(goal_imgs{i}(:,:,3)) .* alpha{i});
    
    % The new mask image takes all the pixels that are bigger than a
    % threshold, this will be usefull for edge detection
    goal_mask_imgs{i} = alpha{i} > mask_threshold(i);
    
    % TODO The same should be done with the mask images, either initialize
    % the temperatures to all active, 2000K or 1500K render once to get
    % synthetic image or add the images as another argument
    mask_imgs{i} = mask_imgs{i} > mask_threshold(i);
    
    %% Show and save the results
    % Reset the current figure in case the user changed to a previous one
    % while learningBasedMatting was being executed
    set(groot, 'CurrentFigure', fig_h(i));
    % Plot and save the output
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(uint8(alpha{i}*255));
    title('Optimized goal mask');
    
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(goal_imgs{i});
    title('New goal image');
    
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(goal_mask_imgs{i});
    title('Binary goal mask');
    
    subtightplot(n_row,n_col,c_fig); imshow(mask_imgs{i});
    title('Binary synthetic image mask');
    
    drawnow;
    
    if isBatchMode()
        print(fig_h(i), save_path{i}, '-dtiff');
    else
        % Activate callabacks for changing alpha in the current image
        text_ui(i).String = ['Binary Threshold ' num2str(mask_threshold(i))];
        slider_ui(i).Enable = 'on';
        slider_ui(i).Callback = @(x,y) alphaCallback(x, y, i);
    end
end

if ~isBatchMode()
    disp('Click continue if the thresholds are correct');
    
    % Activate the callback
    set(button_ui, 'Enable','on');
    set(button_ui, 'Callback', @continueButtonCallback);
    
    % Wait for the user to click accept, to avoid deadlocks, just wait for
    % one figure
    uiwait(fig_h(1));
    
    % Hide all the buttons before saving the figures and keep them
    % hidden as they won't be used after this function
    set(button_ui, 'Visible','off');
    set(slider_ui, 'Visible','off');
end

save_figures_custom(fig_h, save_path);

disp('Done preprocessing input images and masks');

% Callback functions that allow to change the binary threshold and save
% the results if running in GUI mode
    function alphaCallback(hObject, ~, i)
        mask_threshold(i) = hObject.Value;
        text_ui(i).String = ['Binary Threshold ' num2str(mask_threshold(i))];
        
        goal_mask_imgs{i} = alpha{i} > mask_threshold(i);
        mask_imgs{i} = mask_imgs_ori{i} > mask_threshold(i);
        
        set(groot, 'CurrentFigure', hObject.Parent);
        subtightplot(n_row,n_col,5); imshow(goal_mask_imgs{i});
        title('Binary goal mask');
        subtightplot(n_row,n_col,6); imshow(mask_imgs{i});
        title('Binary synthetic image mask');
        drawnow;
    end

    function continueButtonCallback(~,~)
        % Release the lock
        uiresume(fig_h(1));
    end

    function save_figures_custom(fig_h, save_path)
        for j=1:numel(fig_h)
            % Save the image
            print(fig_h(j), save_path{j}, '-dtiff');
        end
        drawnow;
    end
end

