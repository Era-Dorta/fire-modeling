%COMBINEHEATMAP8 Combines two heat maps
%   [V] = COMBINEHEATMAP8(XYZ, V0, V1, MIN, MAX, PART) returns the values after
%   dividing two heatmaps in 8 cubes, taking 4 cubes from each of them and
%   interpolating the values in the intersections. XYZ is a Mx3 matrix of
%   coordinates for each V data, V0, V1 are column vectors of size M of
%   volume values, MIN and MAX are row vectors with the min and max
%   [x, y, z] coordinates of XYZ, V is a column vector of size M with the
%   output values.
%
%  For y = 0	  For y = 1
%
%   ^
% z | 3  4			7  8
%   | 1  2			5  6
%    --->
%     x
%
% PART is a logical row vector 1x8, 1 for the first grid and 0 for the
% second