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

spaces = get_color_space_names();

max_color = cell(size(spaces));
min_color = cell(size(spaces));

% Manually add min and max for RGB, we know is normalized [0,1]
max_color{1} = ones(1,3);
min_color{1} = zeros(1,3);

% All combinations of RGB values from 0 to 255 normalized to [0,1]
num_combinations = 256^3;
in_img = permn(0:255, 3) ./ 255;
%Reshape to image format
in_img = double(reshape(in_img, num_combinations, 1, 3));

% Compute min and max for the rst of color spaces
for i=2:numel(spaces)
    out_color = colorspace([spaces{i},'<-RGB'], in_img);
    out_color = reshape(out_color, num_combinations, 3);
    
    max_color{i} = max(out_color);
    min_color{i} = min(out_color);
end

save(out_file_path, 'max_color', 'min_color', 'spaces');

end

