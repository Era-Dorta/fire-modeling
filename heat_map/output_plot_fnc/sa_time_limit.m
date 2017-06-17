function [stop, options, optchanged] = sa_time_limit( options, ~, ~, startTime )
% Time limit check for sa optimization
optchanged = false;
stop = toc(startTime) > options.TimeLimit;
end


