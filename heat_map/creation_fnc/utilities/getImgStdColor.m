function [ out_rgb ] = getImgStdColor( img, img_mask)
%GETIMGSTDCOLOR Get color estimate from image
%   [ OUT_RGB ] = GETIMGSTDCOLOR( IMG, IMG_MASK) Color is computed using 
%   the standard deviation. IMG is a cell of color images, IMG_MASK a cell
%   of logical mask images. The image/s mean color is given in OUT_RGB.
%
%   See also getImgModeColor, getImgMeanColor

%% Compute histogram of the goal image
out_rgb = zeros(1, size(img{1}, 3));

num_goal = numel(img);

for i=1:num_goal
    if(size(img_mask{i}, 3) > 1)
        img_mask{i} = img_mask{i}(:,:,1);
    end
    
    img{i} = double(img{i});
    for j=1:size(img{i},3)
        sub_img = img{i}(:, :, j);
        out_rgb(j) = out_rgb(j) + std(sub_img(img_mask{i}));
    end
end
out_rgb = out_rgb ./ num_goal;

end

