function [state, options, optchanged] = ga_time_limit( options, state, ~, startTime )
% Time limit check for ga and sa optimization
optchanged = false;
if options.TimeLimit < toc(startTime)
    state.StopFlag = 'time limit exceeded';
end
end

