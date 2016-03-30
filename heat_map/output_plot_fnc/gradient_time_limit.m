function [stop] = gradient_time_limit(~, ~, ~, time_limit, ...
    startTime)
% Force a time limit on gradient descent method
stop = toc(startTime) > time_limit;
end

