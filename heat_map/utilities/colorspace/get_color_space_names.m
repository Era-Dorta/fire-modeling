function [ names ] = get_color_space_names()
%[ NAMES ] = GET_COLOR_SPACE_NAMES()
%   [ NAMES ] = GET_COLOR_SPACE_NAMES() Outputs a cell string of color
%   space names.
%
%   See also colorspace

names = {'RGB', 'YPbPr', 'YCbCr', 'JPEG-YCbCr', 'YDbDr', 'YIQ','YUV', ...
    'HSV', 'HSL', 'HSI', 'XYZ', 'Lab', 'Luv', 'LCH', 'CAT02 LMS'};
end

