function [ out_heatmap ] = decode_permute_ga_solve( x, heat_map )
%DECODE_PERMUTE_GA_SOLVE GA string decode
%   [ OUT_HEATMAP ] = DECODE_PERMUTE_GA_SOLVE( X, HEAT_MAP ) Given a NxM GA
%   population X of indices in do_permute_ga_float_solve, and a 1xN
%   HEAT_MAP distribution. OUT_HEATMAP is the corresponding NxM the heat
%   map distribution
%
%   See also do_permute_ga_float_solve

out_heatmap = zeros(size(x));
for i=1:size(x, 1)
    [~, x(i,:)] = sort(x(i,:));
    out_heatmap(i,:) = heat_map(x(i,:));
end

end

