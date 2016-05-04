function [ fitness ] = heat_map_fitness_approx( heat_map_v, error_foo, ...
    prior_fncs, prior_weights)
%HEAT_MAP_FITNESS_APPROX Heat map fitness function
%   ERROR = HEAT_MAP_FITNESS_APPROX( HEAT_MAP_V, GOAL_IMG, GOAL_MASK)
%   Fitness function for optimization algorithms

error_v = error_foo(heat_map_v);

num_prior_fncs = numel(prior_fncs);
prior_vals = zeros(num_prior_fncs, size(heat_map_v, 1));

for j=1:num_prior_fncs
    prior_vals(j,:) = prior_fncs{j}(heat_map_v);
end

fitness = prior_weights * [error_v; prior_vals];

end
