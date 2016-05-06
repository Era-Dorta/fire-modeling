function [ goal_img, goal_mask, img_mask ] = readGoalAndMask( goal_img_path, ...
    mask_img_path, goal_mask_img_path, resize_goal )
%READGOALANDMASK Summary of this function goes here
%   Detailed explanation goes here

goal_img = cell(numel(goal_img_path), 1);
img_mask = cell(numel(goal_img_path), 1);
goal_mask = cell(numel(goal_img_path), 1);

for i=1:numel(goal_img_path)
    goal_img{i} = imread(goal_img_path{i});
    goal_img{i} = goal_img{i}(:,:,1:3); % Transparency is not used, so ignore it
    
    img_mask{i} = imread(mask_img_path{i});
    
    goal_mask{i} = imread(goal_mask_img_path{i});
    
    if(resize_goal)
        % Resize the goal image to match the render image size
        mask_size = size(img_mask{i});
        goal_img{i} = imresize(goal_img{i}, mask_size(1:2));
        goal_mask{i} = imresize(goal_mask{i}, mask_size(1:2));
    end
    
    % Use a single channel mask
    img_mask{i} = rgb2gray(img_mask{i});
    goal_mask{i} = rgb2gray(goal_mask{i});
end

end

