function [stop, options, optchanged] = sa_time_limit( options, optimvalues, ...
    flag, startTime )
% Time limit check for ga and sa optimization
optchanged = false;
if options.TimeLimit <= toc(startTime)
    stop = false;
else
    disp('Time limit exceeded');
    stop = true;
end
end


