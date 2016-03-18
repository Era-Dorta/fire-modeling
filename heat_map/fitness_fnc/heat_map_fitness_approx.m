function [ cerror ] = heat_map_fitness_approx( heat_map_v, goal_img, ...
    goal_mask)
%HEAT_MAP_FITNESS_APPROX Heat map fitness function
%   ERROR = HEAT_MAP_FITNESS_APPROX( HEAT_MAP_V, GOAL_IMG, GOAL_MASK) 
%   Fitness function for optimization algorithms

cerror =  histogramErrorApprox(heat_map_v, goal_img, goal_mask);

end
