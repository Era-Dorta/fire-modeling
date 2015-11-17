function [ outheapmap ] = filterHeatMapValues( inheatmap, th )
% Removes all the values below the given threshold from the heat map
validVind = find(inheatmap.v >= th);
outheapmap.v = inheatmap.v(validVind);
outheapmap.xyz = inheatmap.xyz(validVind,:);

outheapmap.size = inheatmap.size;
outheapmap.count = size(outheapmap.xyz, 1);
end
