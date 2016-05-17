function [out_file_path] = color_space_max_range()
%COLOR_SPACE_MAX_RANGE Max and minimum range of color spaces
%   [OUT_FILE_PATH] = COLOR_SPACE_MAX_RANGE() Computes the maximum and
%   minimum range of the convertions from RGB to several color spaces and
%   saves the result in OUT_FILE_PATH data file.
%
%   See also colorspace

out_file_path = fullfile(fileparts(mfilename('fullpath')), 'colors_range.mat');

if(exist(out_file_path, 'file'))
    error(['File ' out_file_path ' exits, overwrite not allowed']);
end

spaces = {'YPbPr', 'YCbCr', 'JPEG-YCbCr', 'YDbDr', 'YIQ','YUV', ...
    'HSV', 'HSL', 'HSI', 'XYZ', 'Lab', 'Luv', 'LCH', 'CAT02 LMS'};

in_img = zeros(1,1,3);
max_color = cell(size(spaces));
max_color(:) = {zeros(1,1,3)};

min_color = cell(size(spaces));
min_color(:) = {zeros(1,1,3) + Inf};

for i=1:numel(spaces)
    for j=0:255
        for k=0:255
            for l=0:255
                in_img(:,:,1) = j; in_img(:,:,2) = k; in_img(:,:,3) = l;
                
                out_color = colorspace([spaces{i},'<-RGB'], double(in_img));
                
                max_color{i} = max(max_color{i}, out_color);
                min_color{i} = min(min_color{i}, out_color);
            end
        end
    end
end


save(out_file_path, 'max_color', 'min_color');

end

