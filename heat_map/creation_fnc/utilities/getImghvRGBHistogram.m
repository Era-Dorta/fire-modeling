function [ hc_v, hc_h ] = getImghvRGBHistogram( img, img_mask)
%GETIMGHVRGBHISTOGRAM Get color estimate from image
%   [ HC_V, HC_H ] = GETIMGHVRGBHISTOGRAM( IMG, IMG_MASK)
%
%   See also getColorFromHistoIndex, getImgMeanColor, getImgStdColor

%% Compute histogram of the goal image

size_3 = size(img, 3);
hc_h = zeros(size_3, size(img, 2));
hc_v = zeros(size_3, size(img, 1));

for i=1:size_3
    % Image needs to be in double or the NaN will transform to 0 lowering
    % the mean value
    sub_img = double(img(:, :, i));
    sub_img(~img_mask) = NaN;
    
    hc_h(i,:) = nanmean(sub_img) / (255 * size(img, 1));
    hc_v(i,:) = nanmean(sub_img, 2)' / (255 * size(img, 2));
end

end
