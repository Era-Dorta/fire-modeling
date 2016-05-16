function [stop] = gradsavescores(x, optimValues, state, save_path)
%GRADSAVESCORES Save scores for Gradient Solver
%   [STOP] = GRADSAVESCORES(X, OPTIMVALUES, STATE, SAVE_PATH) To be used as
%   an output function for the gradient solver. It will append the scores 
%   of the initial guess to SAVE_PATH, as well as the scores of the 
%   best individual per iteration and the individual itself.
%
%   See also gradient
persistent BestPopGen BestScores
stop = false;

% In iteration zero is called twice, once with state = 'init' and once with
% state = 'iter', ignore the first one
if isequal('init', state)
    return;
elseif strcmp('done', state)
    save(save_path, 'BestPopGen', 'BestScores', '-append');
    return;
end

% Save the scores and the best point per iteration
if optimValues.iteration == 0
    BestPopGen = x;
    InitialScores = optimValues.fval;
    save(save_path, 'InitialScores', '-append');
    BestScores = InitialScores;
else
    BestPopGen(end + 1, :) = x;
    BestScores(1, end + 1) = optimValues.fval;
end

end
