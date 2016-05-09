function [state, options, optchanged] = ga_max_fnc_eval_limit( options, ...
    state, ~, MaxFunctionEvaluations )
%GA_MAX_FNC_EVAL_LIMIT Fitness function evaluation check for GA
%  [STATE, OPTIONS, OPTCHANGED] = GA_MAX_FNC_EVAL_LIMIT( OPTIONS, ...
%    STATE, ~, MAXFUNCTIONEVALUATIONS ) Add the function as an OutputFcns
%   function in the options for GA. MAXFUNCTIONEVALUATIONS is a positive
%   integer with the maximum number of fitness function evaluations
%   allowed.
%
%   See also ga, gaoptimset, get_ga_options_from_file

optchanged = false;
if state.FunEval >= MaxFunctionEvaluations
    state.StopFlag = 'MaxFunctionEvaluations exceeded';
end
end
