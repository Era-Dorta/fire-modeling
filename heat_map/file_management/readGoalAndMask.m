function [ goal_img, goal_mask, img_mask ] = readGoalAndMask( num_goal, goal_img_path, ...
    mask_img_path, goal_mask_img_path, error_foo )
%READGOALANDMASK Summary of this function goes here
%   Detailed explanation goes here
if(num_goal == 1)
    goal_img = imread(goal_img_path);
    goal_img = goal_img(:,:,1:3); % Transparency is not used, so ignore it
    
    img_mask = logical(imread(mask_img_path));
    
    goal_mask = logical(imread(goal_mask_img_path));
    
    if(isequal(error_foo{1}, @MSE))
        % For MSE the goal and the render image have to be same size
        goal_img = imresize(goal_img, size(img_mask));
        goal_mask = imresize(goal_mask, size(img_mask));
    else
        % For the other error functions use a single channel mask
        img_mask = img_mask(:,:,1);
        goal_mask = goal_mask(:,:,1);
    end
else
    goal_img = cell(numel(goal_img_path), 1);
    img_mask = cell(numel(goal_img_path), 1);
    goal_mask = cell(numel(goal_img_path), 1);
    
    for i=1:numel(goal_img_path)
        goal_img{i} = imread(goal_img_path{i});
        goal_img{i} = goal_img{i}(:,:,1:3); % Transparency is not used, so ignore it
        
        img_mask{i} = logical(imread(mask_img_path{i}));
        
        goal_mask{i} = logical(imread(goal_mask_img_path{i}));
        
        if(isequal(error_foo{1}, @MSE))
            % For MSE the goal and the render image have to be same size
            goal_img{i} = imresize(goal_img{i}, size(img_mask{i}));
            goal_mask{i} = imresize(goal_mask{i}, size(img_mask{i}));
        else
            % For the other error functions use a single channel mask
            img_mask{i} = img_mask{i}(:,:,1);
            goal_mask{i} = goal_mask{i}(:,:,1);
        end
    end
end
end

