function [out_file_path] = color_space_max_range()
%COLOR_SPACE_MAX_RANGE Max and minimum range of color spaces
%   [OUT_FILE_PATH] = COLOR_SPACE_MAX_RANGE() Computes the maximum and
%   minimum range of the convertions from RGB to several color spaces and
%   saves the result in OUT_FILE_PATH data file.
%
%   See also colorspace

out_file_path = fullfile(fileparts(mfilename('fullpath')), 'colors_range.mat');

if(exist(out_file_path, 'file'))
    % error(['File ' out_file_path ' exits, overwrite not allowed']);
end

spaces = {'YPbPr', 'YCbCr', 'JPEG-YCbCr', 'YDbDr', 'YIQ','YUV', ...
    'HSV', 'HSL', 'HSI', 'XYZ', 'Lab', 'Luv', 'LCH', 'CAT02 LMS'};

max_color = cell(size(spaces));
max_color(:) = {zeros(1,3)};

min_color = cell(size(spaces));
min_color(:) = {zeros(1,3) + Inf};

% All combinations of RGB values from 0 to 255.
num_combinations = 256^3;
in_img = permn(0:255, 3);
%Reshape to image format
in_img = double(reshape(in_img, num_combinations, 1, 3));

for i=1:numel(spaces)
    out_color = colorspace([spaces{i},'<-RGB'], in_img);
    out_color = reshape(out_color, num_combinations, 3);
    
    max_color{i} = max(out_color);
    min_color{i} = min(out_color);
end

save(out_file_path, 'max_color', 'min_color', 'spaces');

end

