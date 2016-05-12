function [state, options, optchanged] = gasavescores(options, state, ...
    flag, save_path)
%GASAVESCORES Save scores for GA
%   [STATE, OPTIONS, OPTCHANGED] = GASAVESCORES(OPTIONS, STATE, ...
%   FLAG, SAVE_PATH) To be used as an output function for the ga solver.
%   It will append the scores of the initial population to SAVE_PATH, as
%   well as the scores of the best individual per generation and the
%   individual itself.
%
%   See also ga

persistent BestPopGen InitBest

optchanged = false;

if strcmp(flag, 'done')
    % Save the best individual per generation and its score in a file
    BestScores = [InitBest, state.Best];
    save(save_path, 'BestPopGen', 'BestScores', '-append');
elseif strcmp(flag, 'init')
    % Save the scores for whole initial population
    InitialScores = state.Score;
    save(save_path, 'InitialScores', '-append');
    
    [InitBest, best_idx] = min(InitialScores);
    BestPopGen = state.Population(best_idx, :);
else
    % Assume we have RAM to spare and we rather save the the best
    % individual per generation in a vector
    best_idx = find(state.Score == state.Best(end), 1);
    BestPopGen(state.Generation + 1, :) = state.Population(best_idx, :);
end

end

