function [ fitness ] = heat_map_fitness_approx( heat_map_v, xyz,  whd, ...
    dist_foo, goal_img, goal_mask, lb, ub)
%HEAT_MAP_FITNESS_APPROX Heat map fitness function
%   ERROR = HEAT_MAP_FITNESS_APPROX( HEAT_MAP_V, GOAL_IMG, GOAL_MASK)
%   Fitness function for optimization algorithms

hist_err =  histogramErrorApprox(heat_map_v, goal_img, goal_mask, dist_foo);

% The lower the value the smoother the volume is
smooth_err = smoothnessEstimateGrad(xyz, heat_map_v, whd, lb, ub);

% Up heat val
upheat_err = upHeatEstimate(xyz, heat_map_v, whd);

% High values -> more heat up -> invert value
upheat_err = 1.0 - upheat_err;

% Relative weights for histogram, smoothness and upheat estimates.
% If we want the fitness function to be [0,1] the weights must sum
% up to one
e_weights = [1/3, 1/3, 1/3];

% Final fitness of each individual is the sum of each error weighted by
% e_weights
fitness = e_weights * [hist_err; smooth_err; upheat_err;];

end
