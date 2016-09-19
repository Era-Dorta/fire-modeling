function [ result ] = getInitHeatMap_icm( hm, LB, UB )
%GETINITHEATMAP_ICM

result = bsxfun(@max, hm.v', LB);
result = bsxfun(@min, result, UB);
end
