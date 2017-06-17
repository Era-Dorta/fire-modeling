function [stop,options,optchanged] = option_fn_wrapper(options,optimvalues,flag, fnc)
%OPTION_FN_WRAPPER Output function wrapper for SA and GA
%   Lets Simulated annealing use all the gradient output functions
optchanged = false;
% Iteration values in simulated annealing are increased by one
optimvalues.iteration = optimvalues.iteration - 1;
stop = fnc(optimvalues.x, optimvalues, flag);
end

