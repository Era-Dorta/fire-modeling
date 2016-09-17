function [lb, ub] = update_temperature_range_icm(i, cur_temp, t, lb, ub)
step_bounds = t(2) - t(1);
mean_ublb = mean([lb(i), ub(i)]);

% Reduce the bounds
if cur_temp > mean_ublb
    lb(i) = lb(i) + step_bounds;
else
    ub(i) = ub(i) - step_bounds;
end
end