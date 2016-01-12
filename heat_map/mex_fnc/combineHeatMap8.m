%COMBINEHEATMAP8 Combines two heat maps
%   [V] = COMBINEHEATMAP8(XYZ, V0, V1, MIN, MAX, RATIO) returns the values
%   after dividing two heatmaps in 8 cubes, interpolating with 
%   V = V0 * (RATIO + rand) + V1 * (1 - RATIO + rand).  
%   XYZ is a Mx3 matrix of coordinates for each V data, V0, V1 are column 
%   vectors of  size M of volume values, MIN and MAX are row vectors with 
%   the min and  max [x, y, z] coordinates of XYZ, V is a column vector of 
%   size M with  the output values.
%