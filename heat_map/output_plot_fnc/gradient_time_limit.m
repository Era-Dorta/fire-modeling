function [stop] = gradient_time_limit(x, optimValues, state, time_limit)
% Force a time limit on gradient descent method
    stop = time >= time_limit + time;
end

