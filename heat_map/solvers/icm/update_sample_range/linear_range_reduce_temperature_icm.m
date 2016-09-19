function [lb, ub] = linear_range_reduce_temperature_icm(i, cur_temp, t, lb, ub)
%LINEAR_RANGE_REDUCE_TEMPERATURE_ICM

% [0,1] percentage of the space that will be discarded
reduce_factor = 0.2;

max_dist = ub(i) - lb(i);

% Distance from the lower bound to the current temperature
lb_dist = (cur_temp - lb(i)) / max_dist;

% If current temperature is in the middle, shrink both bounds by half of
% the reduce factor, otherwise divide the reduction linearly according to
% distance to the bounds
lb(i) = lb(i) + (lb_dist) * reduce_factor * max_dist;
ub(i) = ub(i) - (1 - lb_dist) * reduce_factor * max_dist;

% TODO If current temperature is on a bound increase the bound if possible
end
