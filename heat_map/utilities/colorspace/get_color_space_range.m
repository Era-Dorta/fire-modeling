function [ min_range, max_range ] = get_color_space_range( color_space )
%GET_COLOR_SPACE_RANGE Get color space min and max range
%   [ MIN_RANGE, MAX_RANGE ] = GET_COLOR_SPACE_RANGE( COLOR_SPACE ) Given a
%   color space name or index COLOR_SPACE, its minimum and maximum range
%   are given in MIN_RANGE, MAX_RANGE.
%
%   See also get_color_space_names, colorspace

persistent COLOR_SPACE_DATA

if isempty(COLOR_SPACE_DATA)
    % Load data file only once
    data_file_path = fullfile(fileparts(mfilename('fullpath')), 'colors_range.mat');
    COLOR_SPACE_DATA = load(data_file_path);
end

% Get index of color_space name
if ischar(color_space)
    color_idx = find(strcmp(COLOR_SPACE_DATA.spaces, color_space));
else
    color_idx = color_space;
end

if isempty(color_idx)
    error(['Invalid color space name ''' color_space '''']);
end

min_range = COLOR_SPACE_DATA.min_color{color_idx};
max_range = COLOR_SPACE_DATA.max_color{color_idx};
end

