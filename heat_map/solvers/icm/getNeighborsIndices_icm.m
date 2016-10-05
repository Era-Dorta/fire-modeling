function [neigh_idx] = getNeighborsIndices_icm(i, xyz, NeighbourhoodSize)
persistent N_I

if isempty(N_I)
    N_I = precompute_neight_indices( xyz, NeighbourhoodSize);
end

neigh_idx = [N_I{i}];

end