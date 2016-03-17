function [ cerror ] = heat_map_fitness_approx( heat_map_v, goal_img, ...
    goal_mask)
%HEAT_MAP_FITNESS_APPROX Heat map fitness function
%   ERROR = HEAT_MAP_FITNESS_APPROX( HEAT_MAP_V, GOAL_IMG, GOAL_MASK) 
%   Fitness function for optimization algorithms

cerror = zeros(1, size(heat_map_v, 1));

for i=1:size(heat_map_v, 1)
   cerror(i) =  histogramErrorApprox(heat_map_v(i,:), goal_img, goal_mask);
end

end
