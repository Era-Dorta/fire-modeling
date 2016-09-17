function [neigh_idx] = getNeighborsIndices_icm(i, xyz)
% Get ith voxel xyz coordinates
idx = xyz(i,:);

% Offsets for up, bottom, left and right neighbours
neigh_offset = [1, 0, 0; -1, 0, 0; 0, 1, 0; 0, -1, 0; 0, 0, 1; 0, 0, -1];

% xyz for indices for the neighbours
neigh_idx = bsxfun(@plus, neigh_offset, idx);
end