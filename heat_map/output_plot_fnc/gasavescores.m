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

persistent AllPopulation AllScores

optchanged = false;

if strcmp(flag, 'done')
    % Save the data
    save(save_path, 'AllPopulation', 'AllScores', '-append');
elseif strcmp(flag, 'init')
    % Save the scores for whole initial population
    InitialScores = state.Score';
    PopulationSize = options.PopulationSize;
    save(save_path, 'InitialScores', 'PopulationSize', '-append');
    
    AllScores = InitialScores;
    AllPopulation = state.Population;
else
    % Assume we have RAM to spare and we rather save all the population and
    % all the scores
    AllPopulation = [AllPopulation; state.Population];
    AllScores = [AllScores; state.Score'];
end

end

