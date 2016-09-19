function score = neighbour_distance_term_icm(i, n_i, x, ~, lb, ub)
score = ones(1, size(x, 1));

% Get the neighbours temperatures
neigh = x(1, n_i);

if(~isempty(neigh))
    % Inverse maximum neighbour distance
    inv_factor = 1 / ((ub(i) - lb(i)) * numel(neigh));
    
    if ~isinf(inv_factor)
        % Normalised sum of the absolute distance to each neighbour
        % for all the possible voxel temperatures in x(:,i)
        score = nansum(abs(bsxfun(@minus, x(:, i), neigh)), 2)' ...
            * inv_factor;
    end
end
end