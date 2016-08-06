%COMBINEHEATMAP2POINT Combines two heat maps
%   [V] = COMBINEHEATMAP2POINT(XYZ, V0, V1, MIN, MAX, RATIO, SEED) returns
%   the values taking a random cube from the second heatmap and inserting 
%   in teh first using the interpolation RATIO, 
%   V = V0 * RATIO +  V1 * ( 1 - RATIO).  
%   XYZ is a Mx3 matrix of coordinates for each V data, V0, V1 are column 
%   vectors of  size M of volume values, MIN and MAX are row vectors with 
%   the min and  max [x, y, z] coordinates of XYZ, V is a column vector of 
%   size M with  the output values.
%