function [ hc_goal_v, hc_goal_h ] = getImghvRGBHistogram( img, img_mask)
%GETIMGHVRGBHISTOGRAM Get color estimate from image
%   [ HC_GOAL ] = GETIMGHVRGBHISTOGRAM( IMG, IMG_MASK, N_BINS)
%
%   See also getColorFromHistoIndex, getImgMeanColor, getImgStdColor

%% Compute histogram of the goal image

size_3 = size(img, 3);
hc_goal_v = zeros(size_3, size(img, 1));
hc_goal_h = zeros(size_3, size(img, 2));

for i=1:size_3
    sub_img = img(:, :, i);
    sub_img(~img_mask) = NaN;
    hc_goal_v(i,:) = nanmean(sub_img) / 255;
    hc_goal_h(i,:) = nanmean(sub_img, 2)' / 255;
end

end
