function [ fitness ] = heat_map_fitness_approx( heat_map_v, xyz,  whd, ...
    error_foo, lb, ub)
%HEAT_MAP_FITNESS_APPROX Heat map fitness function
%   ERROR = HEAT_MAP_FITNESS_APPROX( HEAT_MAP_V, GOAL_IMG, GOAL_MASK)
%   Fitness function for optimization algorithms

hist_err =  error_foo(heat_map_v);

% The lower the value the smoother the volume is
smooth_err = smoothnessEstimateGrad(xyz, heat_map_v, whd, lb, ub);

% Up heat val
upheat_err = upHeatEstimate(xyz, heat_map_v, whd);

% Relative weights for histogram, smoothness and upheat estimates.
% If we want the fitness function to be [0,1] the weights must sum
% up to one
e_weights = [1/3, 1/3, 1/3];

% Final fitness of each individual is the sum of each error weighted by
% e_weights
fitness = e_weights * [hist_err; smooth_err; upheat_err;];

end
