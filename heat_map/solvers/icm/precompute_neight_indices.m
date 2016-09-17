function [ neigh_i ] = precompute_neight_indices( xyz )
%PRECOMPUTE_NEIGHT_INDICES
neigh_i = cell(size(xyz,1), 1);

for i=1:size(xyz,1)
    [neigh_idx] = getNeighborsIndices_local(i, xyz);
    neigh_i{i} = [];
    for j=1:size(neigh_idx, 1)
        [~,indx] = ismember(neigh_idx(j,:),xyz,'rows');
        if indx ~= 0
            neigh_i{i}(end+1) = indx;
        end
    end
end

    function [neigh_idx] = getNeighborsIndices_local(i, xyz)
        % Get ith voxel xyz coordinates
        idx = xyz(i,:);
        
        % Offsets for right, leaft, up, bottom, front and behind
        neigh_offset = [1, 0, 0;
            -1, 0, 0;
            0, 1, 0;
            0, -1, 0;
            0, 0, 1;
            0, 0, -1];
        
        % xyz for indices for the neighbours
        neigh_idx = bsxfun(@plus, neigh_offset, idx);
    end

end

