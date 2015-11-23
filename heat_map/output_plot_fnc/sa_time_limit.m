function [stop, options, optchanged] = sa_time_limit( options, ~, ~, startTime )
% Time limit check for sa optimization
optchanged = false;
c_time = toc(startTime);

if options.TimeLimit >= c_time
    stop = false;
else
    stop = true;
end
end


