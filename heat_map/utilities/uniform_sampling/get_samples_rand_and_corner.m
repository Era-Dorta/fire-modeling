function [ heat_map_v, bin_norm ] = get_samples_rand_and_corner( opts )
%GET_SAMPLES_RAND_AND_CORNER Get random samples using several methods

max_norm = zeros(opts.hm_count, 1) + opts.UB;
max_norm = max_norm - opts.LB;
max_norm = norm(max_norm);

edges_s = linspace(0, max_norm, opts.samples_n_bins + 1);
edges_s(end) = edges_s(end) + eps;

norm_step = edges_s(2) - edges_s(1);

bin_norm = edges_s(1:end - 1) + norm_step/2;

mean_bounds = mean([opts.LB, opts.UB]);

% Increase to try more times use pure random samples
max_tries1 = 25;
max_tries2 = 25;

l_steps = linspace(0, norm_step, max_tries1);

% Copy data to have more efficient parfor evaluation
num_samples = opts.num_samples;
hm_count = opts.hm_count;
lb = opts.LB;
ub = opts.UB;

% Parfor as it is quite computationally intensive
parfor j=1:opts.samples_n_bins
    heat_map_v{j} = zeros(num_samples, hm_count);
    mean_norm = mean(edges_s(j:j+1)); %#ok<PFBNS>
    
    for i=2:2:num_samples
        valid_sample = false;
        perturbation = zeros(1, hm_count);
        
        %% First case, generate random sample, generate perturbation
        % of desired norm and add it to the sample
        n_tries = 1;
        while ~valid_sample && n_tries <= max_tries1
            
            n_tries = n_tries + 1;
            
            heat_map_v{j}(i-1,:) = rand(1, hm_count);
            heat_map_v{j}(i-1,:) = fitToRange(heat_map_v{j}(i-1,:), 0, 1, lb, ub);
            
            % Generate a random perturbation of the solution
            perturbation = rand(1, hm_count) - 0.5;
            
            % Normalize each sample
            perturbation = perturbation / norm(perturbation);
            
            heat_map_v{j}(i,:) = heat_map_v{j}(i-1,:) + perturbation * mean_norm;
            
            % Make the sample be within the bounds
            heat_map_v{j}(i,:) = max(heat_map_v{j}(i,:), lb);
            heat_map_v{j}(i,:) = min(heat_map_v{j}(i,:), ub);
            
            h_norm = norm(heat_map_v{j}(i-1,:) - heat_map_v{j}(i,:));
            
            if h_norm >= edges_s(j) && h_norm < edges_s(j+1)
                valid_sample = true;
            end
        end
        
        %% Second case, gradually increase the permutation norm
        % up to the next norm
        k=1;
        while ~valid_sample && k <= max_tries2
            
            heat_map_v{j}(i,:) = heat_map_v{j}(i-1,:) + ...
                perturbation * (mean_norm + l_steps(k)); %#ok<PFBNS>
            
            % Make the sample be within the bounds
            heat_map_v{j}(i,:) = max(heat_map_v{j}(i,:), lb);
            heat_map_v{j}(i,:) = min(heat_map_v{j}(i,:), ub);
            
            h_norm = norm(heat_map_v{j}(i-1,:) - heat_map_v{j}(i,:));
            
            if h_norm >= edges_s(j) && h_norm < edges_s(j+1)
                valid_sample = true;
            end
            k = k + 1;
        end
        
        %% Third case pull the samples towards the corners
        if ~valid_sample
            % Get closer corner for the first sample
            c1 = heat_map_v{j}(i-1,:);
            ub_idx = (c1 >= mean_bounds);
            c1(ub_idx) = ub;
            c1(~ub_idx) = lb;
            
            % Compute opposite corner
            c2 = c1;
            c2(~ub_idx) = ub;
            c2(ub_idx) = lb;
            
            % Recompute the second pair
            heat_map_v{j}(i,:) = heat_map_v{j}(i-1,:) + perturbation * mean_norm;
            heat_map_v{j}(i,:) = max(heat_map_v{j}(i,:), lb);
            heat_map_v{j}(i,:) = min(heat_map_v{j}(i,:), ub);
            
            % Recompute initial norm
            prev_h_norm = norm(heat_map_v{j}(i-1,:) - heat_map_v{j}(i,:));
            
            % Initialy do not use the corners
            i_val = 0;
            i_step = 0.1; % 10% initial step size
            
            while ~valid_sample
                
                % Interpolate between the samples and their corners
                h_1 = heat_map_v{j}(i-1,:) * (1 - i_val) + c1 * i_val;
                h_2 = heat_map_v{j}(i,:) * (1 - i_val) + c2 * i_val;
                
                h_norm = norm(h_1 - h_2);
                
                % Under the lower bin
                if h_norm < edges_s(j)
                    % If the previous norm is larger it must have
                    % been above the larger bin, so we overstepped
                    % down, so decrease step size
                    if h_norm < prev_h_norm
                        i_step = i_step * 0.5;
                    end
                    
                    % Increase interpolation to add more corner
                    i_val = i_val + i_step;
                    i_val = min(i_val, 1);
                    
                else % Above the higher bin
                    % Overstepped high
                    if h_norm > prev_h_norm
                        i_step = i_step * 0.5;
                    end
                    
                    % Decreate interpolation rate
                    i_val = i_val - i_step;
                    i_val = max(i_val, 0);
                end
                
                if h_norm >= edges_s(j) && h_norm < edges_s(j+1)
                    valid_sample = true;
                    heat_map_v{j}(i-1,:) = h_1;
                    heat_map_v{j}(i,:) = h_2;
                end
            end
        end
    end
end

end

