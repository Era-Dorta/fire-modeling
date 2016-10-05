function [neigh_idx] = getNeighborsIndices_icm_re(i, xyz, NeighbourhoodSize)
%GETNEIGHBORSINDICES_ICM_RE
%   [NEIGH_IDX] = GETNEIGHBORSINDICES_ICM_RE(I, XYZ, NEIGHBOURHOODSIZE)

neigh_idx = getNeighborsIndices_icm(i, xyz, NeighbourhoodSize);

% As i is a collection of points, remove all the elements in the neighbours
% that are already in i, and also deleted the repeated values
if numel(i) > 1
    % unique() and ismember() are expensive functions, the if provides up
    % to 10x speed up
    neigh_idx = unique(neigh_idx(~ismember(neigh_idx,i)));
end

end