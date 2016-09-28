function score = neighbour_distance_exp2_term_icm(i, n_i, x, options, lb, ub)
%NEIGHBOUR_DISTANCE_EXP2_TERM_ICM sum(exp(((x - neigh)^2)*w0))*w1

score = ones(1, size(x, 1));

% Get the neighbours temperatures
neigh = x(1, n_i);

if(~isempty(neigh))
    % Inverse maximum neighbour distance
    inv_factor = 1 / ((ub(i) - lb(i)) * numel(neigh));
    
    if ~isinf(inv_factor)
        % score = sum(exp((x(:,i) - neighbours)^2*w0))*w1
        % Exponentiate to further penalise large temperature differences,
        % exp(0) = 1, so remove number of neighbours to have 0 error when
        % they are all the same
        score = (bsxfun(@minus, x(:, i), neigh).^2) * ...
            inv_factor * options.NeighDistExpFactor(1);
        
        score = sum(exp(score), 2)' * options.NeighDistExpFactor(2) ...
            - numel(neigh);
    end
end
end