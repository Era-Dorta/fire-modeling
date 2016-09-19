function [ result ] = getInitHeatMapScaled_icm( hm, LB, UB )
%GETINITHEATMAPSCALED_ICM

factor = mean([LB, UB])/mean(hm.v);
result = bsxfun(@max, hm.v' * factor, LB);
result = bsxfun(@min, result, UB);
end
