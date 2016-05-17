function [out_imgs] = colorspace_transform_imgs(in_imgs, in_space, out_space)
%COLORSPACE_TRANSFORM_IMGS Transforms images between color spaces
%   [OUT_IMGS] = COLORSPACE_TRANSFORM_IMGS(IN_IMGS, IN_SPACE, OUT_SPACE)
%   Transform cell of images IN_IMGS in uint8 format from color space
%   IN_SPACE to color space OUT_SPACE. The result is in cell of images
%   OUT_IMGS in uint8 format.
%
%   See also colorspace

if strcmp(in_space, out_space)
    out_imgs = in_imgs;
else
    [min_range_in, max_range_in ] = get_color_space_range(in_space);
    [min_range_out, max_range_out ] = get_color_space_range(out_space);
    out_imgs = cell(size(in_imgs));
    
    for i=1:numel(in_imgs)
        % Transform unit8 image to double
        out_imgs{i} = double(in_imgs{i});
        for j=1:size(out_imgs{i}, 3)
            out_imgs{i}(:,:,j) = fitToRange(out_imgs{i}(:,:,j), 0, 255, ...
                min_range_in(j), max_range_in(j));
        end
        
        % Convert to new color space
        out_imgs{i} = colorspace([out_space,'<-', in_space], out_imgs{i});
        
        % Revert to uint8 [0,255]
        for j=1:size(out_imgs{i}, 3)
            out_imgs{i}(:,:,j) = fitToRange(out_imgs{i}(:,:,j), ...
                min_range_out(j), max_range_out(j), 0, 255);
        end
        out_imgs{i} = uint8(out_imgs{i});
    end
end

end