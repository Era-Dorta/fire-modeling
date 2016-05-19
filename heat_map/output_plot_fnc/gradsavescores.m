function [stop] = gradsavescores(x, optimValues, state, save_path)
%GRADSAVESCORES Save scores for Gradient Solver
%   [STOP] = GRADSAVESCORES(X, OPTIMVALUES, STATE, SAVE_PATH) To be used as
%   an output function for the gradient solver. It will append the scores
%   of the initial guess to SAVE_PATH, as well as the scores of the
%   best individual per iteration and the individual itself.
%
%   See also gradient
persistent AllPopulation AllScores
stop = false;

% In iteration zero is called twice, once with state = 'init' and once with
% state = 'iter', ignore the first one
if isequal('init', state)
    return;
elseif strcmp('done', state)
    save(save_path, 'AllPopulation', 'AllScores', '-append');
    return;
end

% Save the scores and the best point per iteration
if optimValues.iteration == 0
    AllPopulation = x;
    InitialScores = optimValues.fval;
    PopulationSize = 1;
    save(save_path, 'InitialScores', 'PopulationSize','-append');
    AllScores = InitialScores;
else
    AllPopulation(end + 1, :) = x;
    AllScores(end + 1, 1) = optimValues.fval;
end

end
