function [ result ] = getMeanTemp_icm( ~, LB, UB )
%GETMEANTEMP_ICM

result = repmat(mean([LB, UB]), 1, size(LB, 2));
end
