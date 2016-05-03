function [ goal_imgs, goal_mask_imgs, mask_imgs ] = preprocess_images( ...
    goal_imgs, goal_mask_imgs, mask_imgs, figurePath)
%PREPROCESS_IMAGES Image preprocessing for heatMapReconstruction
%    [ OUT_IMGS, OUT_MASKS ] = PREPROCESS_IMAGES( IN_IMGS, MASK_IMGS )

n_row = 2;
n_col = 3;
c_fig = 1;

% In the method, background is usually around 1e-10
mask_threshold = 1e-6;

disp('Preprocessing input images and masks');

for i=1:numel(goal_imgs)
    
    istr = num2str(i);
    
    % Conver the scrible mask image to a trimap image
    mask=zeros(size(goal_mask_imgs{i},1),size(goal_mask_imgs{i},2));
    fore=(goal_mask_imgs{i}==255);
    back=(goal_mask_imgs{i}==0);
    
    mask(fore(:,:,1))=1;
    mask(back(:,:,1))=-1;
    
    % Plot the goal image and the trimap
    c_fig = 1;
    fig_h = figure('Name', ['Goal and mask images ' istr]);
    
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(goal_imgs{i});
    title('Original goal image');
    
    mask_show = mask;
    mask_show(mask_show ~= -1 & mask_show ~= 1) = 0.5;
    mask_show(mask_show == -1) = 0;
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(mask_show);
    title('Original goal trimap');
    
    drawnow;
    
    % Compute the alpha matte
    alpha = learningBasedMatting(goal_imgs{i}, mask);
    
    % Get the new goal image without the background
    goal_imgs{i}(:,:,1) = uint8(double(goal_imgs{i}(:,:,1)) .* alpha);
    goal_imgs{i}(:,:,2) = uint8(double(goal_imgs{i}(:,:,2)) .* alpha);
    goal_imgs{i}(:,:,3) = uint8(double(goal_imgs{i}(:,:,3)) .* alpha);
    
    % The new mask image takes all the pixels that are bigger than a
    % threshold, this will be usefull for edge detection
    goal_mask_imgs{i} = alpha > mask_threshold;
    
    % TODO The same should be done with the mask images, either initialize
    % the temperatures to all active, 2000K or 1500K render once to get
    % synthetic image or add the images as another argument
    mask_imgs{i} = mask_imgs{i} > mask_threshold;
    
    % Plot and save the output
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(uint8(alpha*255));
    title('Optimized goal mask');
    
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(goal_imgs{i});
    title('New goal image');
    
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(goal_mask_imgs{i});
    title('Binary goal mask');
    
    subtightplot(n_row,n_col,c_fig); imshow(mask_imgs{i});
    title('Binary synthetic image mask');
    
    drawnow;
    
    print(fig_h, [figurePath istr '.tif'], '-dtiff');
    
end

disp('Done preprocessing input images and masks');

