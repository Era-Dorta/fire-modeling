function [ norm_names ] = get_norm_names( name, ext, num_names )
%GET_NORM_NAMES Get names with number
%   [ NORM_NAMES ] = GET_NORM_NAMES( NAME, EXT, NUM_NAMES ) NORM_NAMES is a
%   cell string where each entry is [NAME i EXT] where i goes from 1 to 
%   NUM_NAMES


norm_names = cell(1, num_names);

for i=1:num_names
    norm_names{i} = [name num2str(i) ext];
end

