function score = neighbour_distance_exp_term_icm(i, n_i, x, options, lb, ub)
score = ones(1, size(x, 1));

% Get the neighbours temperatures
neigh = x(1, n_i);

if(~isempty(neigh))
    % Inverse maximum neighbour distance
    inv_factor = 1 / ((ub(i) - lb(i)) * numel(neigh));
    
    if ~isinf(inv_factor)
        % Normalised sum of the absolute distance to each neighbour
        % for all the possible voxel temperatures in x(:,i)
        % Exponentiate to further penalise large temperature differences,
        % exp(0) = 1, so remove number of neighbours to have 0 error when
        % they are all the same
        score = sum(exp(abs(bsxfun(@minus, x(:, i), neigh)) * ...
            inv_factor * options.NeighDistExpFactor), 2)' - numel(neigh);
    end
end
end