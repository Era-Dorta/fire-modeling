function [ neigh_i ] = precompute_neight_indices( xyz, NeighbourhoodSize )
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
        switch(NeighbourhoodSize)
            case 0
                % 4 neighbours in direct line
                neigh_offset = [1, 0, 0;
                    -1, 0, 0;
                    0, 1, 0;
                    0, -1, 0;
                    0, 0, 1;
                    0, 0, -1];
            case 1
                % 18 neighbours, includes diagonals
                neigh_offset = [
                    0, 0, 1;
                    0, 1, 0;
                    0, 1, 1;
                    1, 0, 0;
                    1, 0, 1;
                    1, 1, 0;
                    0, 0, -1;
                    0, -1, 0;
                    0, 1, -1;
                    -1, 0, 0;
                    1, 0, -1;
                    1, -1, 0;
                    0, -1, 1;
                    -1, 0, 1;
                    -1, 1, 0;
                    0, -1, -1;
                    -1, 0, -1;
                    -1, -1, 0];
            otherwise
                if NeighbourhoodSize < 0
                    error('Neibourhood size must be positive');
                end
                % General case, a square around the point of size
                % NeighbourhoodSize -1
                neigh = NeighbourhoodSize - 1;
                x = -neigh:neigh;
                n = 3;
                
                m = length(x);
                X = cell(1, n);
                [X{:}] = ndgrid(x);
                X = X(end : -1 : 1);
                neigh_offset = cat(n+1, X{:});
                neigh_offset = reshape(neigh_offset, [m^n, n]);
                
                % Remove the point index
                neigh_offset(round(size(neigh_offset, 1) / 2), :) = [];
        end
        % xyz for indices for the neighbours
        neigh_idx = bsxfun(@plus, neigh_offset, idx);
    end

end

