function [V, XYZ] = combineHeatMap8(XYZ0, V0, V1, MIN, MAX)
%combineHeatMap8 Combines two heat maps
%   [V, XYZ] = combineHeatMap8(XYZ0, V0, V1, MIN, MAX) returns the values after
%   dividing two heatmaps in 8 cubes, taking 4 cubes from each of them and
%   interpolating the values in the intersections. XYZ0 is a Mx3 matrix of 
%   coordinates for each V data, V0, V1 are column vectors of size M of
%   volume values, MIN and MAX are row vectors with the min and max 
%   [x, y, z] coordinates of XYZ0, V is a column vector of size M with the
%   output values and XYZ is a Mx3 matrix of coordinates for each V data.


