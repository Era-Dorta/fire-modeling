function [ x, fval, exitFlag, output ] = icm ( fun, x0, xyz, lb, ub, options)
%ICM Iterative Conditional Modes parallel solver

exitFlag = 0;
num_dim = numel(x0);

cur_score = ones(num_dim, 1);
t = linspace(lb(1), ub(1), options.TemperatureNSamples);

% Replicate x to be able to evaluate in parallel
x = repmat(x0, options.TemperatureNSamples, 1);

% Copy the data using an interpolant for easy access using the xyz coords
x_interp = scatteredInterpolant(xyz(:, 1), xyz(:, 2), xyz(:, 3), ...
    x0', 'nearest', 'none' );
warning('off', 'MATLAB:scatteredInterpolant:InterpEmptyTri3DWarnId');

optimValues.fval = 1;
optimValues.iteration = 0;
optimValues.funcCount = 0;

state = 'init';
call_output_fnc();

state = 'iter';

while(true)
    
    current_score = mean(cur_score);
    
    % Iterate for each voxel
    for i=1:num_dim
        
        % Get score for the current voxel
        min_score = cur_score(i);
        cur_temp = x(1, i);
        
        % Assign a different temperature to each copy of x
        x(:, i) = t;
        
        % Compute all the scores
        new_score = calculate_score(i, x);
        
        % Get the min
        [new_score, j] = min(new_score);
        
        % Update on improvement
        if (new_score < min_score)
            cur_temp = t(j);
            min_score = new_score;
        end
        
        % Set the voxel to have the best temperature so far
        x(:, i) = cur_temp;
        update_interpolant_temperatures(i, cur_temp);
        cur_score(i) = min_score;
        
    end
    
    optimValues.fval = mean(cur_score);
    
    display_info();
    
    if(call_output_fnc())
        state = 'interrupt';
        exitFlag = -1;
        break;
    end
    
    if (abs(optimValues.fval-current_score ) < options.FunctionTolerance || ...
            optimValues.iteration > options.MaxIterations || ...
            optimValues.funcCount > options.MaxFunctionEvaluations)
        break;
    end
    
    optimValues.iteration = optimValues.iteration + 1;
end

state = 'done';
fval = optimValues.fval;

output = optimValues;

call_output_fnc();

% Remove the copies of x
x = x(1,:);

warning('on', 'MATLAB:scatteredInterpolant:InterpEmptyTri3DWarnId');

    function [stop] = call_output_fnc()
        stop = false;
        for k=1:numel(options.OutputFcn)
            if(options.OutputFcn{k}(x(1,:), optimValues, state))
                stop = true;
            end
        end
    end

    function [score] = calculate_score(i, x)
        
        score = data_term_score(i, x) * 0.8;
        
        n_xyz = getNeighborsIndices(i);
        
        score = score + pairwise_term(i, n_xyz, x) * 0.2;
    end

    function [score] = data_term_score(i, x)
        
        score = fun(x);
        optimValues.funcCount = optimValues.funcCount + options.TemperatureNSamples;
        
    end

    function display_info()
        if strcmp(options.Display, 'iter')
            if mod(optimValues.iteration, 25) == 0
                disp('Iter F-count           f(x)');
            end
            fprintf('% 4d %7d    %.5e\n', optimValues.iteration, ...
                optimValues.funcCount, optimValues.fval);
        end
    end

    function [neigh_idx] = getNeighborsIndices(i)
        % Get ith voxel xyz coordinates
        idx = xyz(i,:);
        
        % Offsets for up, bottom, left and right neighbours
        neigh_offset = [1, 0, 0; -1, 0, 0; 0, 1, 0; 0, -1, 0; 0, 0, 1; 0, 0, -1];
        
        % xyz for indices for the neighbours
        neigh_idx = bsxfun(@plus, neigh_offset, idx);
    end

    function update_interpolant_temperatures(i, t)
        x_interp.Values(i) = t;
    end

    function score = pairwise_term(i, n_xyz, x)
        score = zeros(1, options.TemperatureNSamples);
        
        % Get the neighbours temperatures
        neigh = x_interp(n_xyz);
        
        if(~isempty(neigh))
            % Inverse maximum neighbour distance
            inv_factor = 1 / ((ub(1) - lb(1)) * sum(isnan(neigh)));
            
            % Compute it for all the possible temperature samples in the
            % ith voxel
            for k=1:options.TemperatureNSamples
                score(k) = nansum(abs(bsxfun(@minus, x(k, i), neigh))) * inv_factor;
            end
        end
    end
end

