function [neigh_idx] = getNeighborsIndices_icm(i, xyz)
persistent N_I

if isempty(N_I)
    N_I = precompute_neight_indices( xyz );
end

neigh_idx = N_I{i};

end