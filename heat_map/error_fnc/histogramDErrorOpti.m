function [ cerror ] = histogramDErrorOpti( goal_imgs, test_imgs, goal_mask, ...
    img_mask)
%HISTOGRAMDERROROPTI Compues an error measure between several images
%   CERROR = HISTOGRAMDERROROPTI(GOAL_IMGS, TEST_IMGS, GOAL_MASK, IMG_MASK)
%   similar to HISTOGRAM_ERROR, assumes RGB images, for the catching
%   mechanism to work consistently, if the goal image changes, call
%   clear 'HISTOGRAMDERROROPTI'; It extends the histogram comparison to 3D,
%   the extra dimension is the pixel distance to the edges.
%   GOAL_IMGS and TEST_IMGS are same sized cells with the images to
%   compare, GOAL_MASK and IMG_MASK are same sized cells with logical
%   two dimensional matrices to mask GOAL_IMGS and TEST_IMGS respectively.
%
%   See also HISTOGRAMERROR, HISTOGRAMERROROPTI

persistent HC_GOAL EDGESD

% Create 255 bins, images are uint in the range of 0..255
edges = linspace(0, 255, 256);

% Number of bins for the distances
n_bins_dist = 4;

if isempty(HC_GOAL)
    % Edges for the distance histograms
    EDGESD = cell(numel(goal_imgs), 1);
    
    HC_GOAL = cell(numel(goal_imgs), n_bins_dist);
    
    for i=1:numel(goal_imgs)
        
        % Idea0: max distance -> the distance between two diagonal corners
        % max_dist = norm([size(goal_imgs{i}, 1), size(goal_imgs{i}, 2)]);
        
        % Idea1: max distance -> the distance between corners in the mask
        % image
        [x_idx, y_idx] = find(goal_mask{i} == 1);
        max_dist = norm([max(x_idx) - min(x_idx), max(y_idx) - min(y_idx)]);
        
        % Idea1.1: max distance -> distance from the center to a corner
        % image, assuming square mask.
        max_dist = max_dist / 2;
        
        % The edges are of size N + 1, where each bin would contain X if
        % edges(j) <= X(i) < edges(j+1) for 1 <= j < N
        EDGESD{i} = linspace(0, max_dist, n_bins_dist + 1);
        
        for j=1:3 % For each color channel
            sub_img = goal_imgs{i}(:, :, j);
            
            dist_img = ones(size(sub_img));
            dist_img(goal_mask{i}) = 0; % Set inside of the goal mask to 0
            
            % Compute the distance of all the zero pixels to the closest 1
            % pixels, i.e. distance to the edge for each pixel
            dist_img = bwdist(dist_img);
            
            % Get a new image where each value indicates the distance
            % bin that the pixel belongs to
            d_bin = discretize(dist_img, EDGESD{i});
            
            % For each distance bin compute a color histogram, the edges
            % are of size N + 1, where each bin would contain X if
            % edges(j) <= X(i) < edges(j+1) for 1 <= j < N
            for k=1:n_bins_dist
                % Get a new mask than only has the pixels within the
                % current distance.
                new_mask = goal_mask{i} & (d_bin == k);
                HC_GOAL{i, k}(j, :) = histcounts( sub_img(new_mask), edges);
                
                % Normalize by the number of valid pixels
                valid_p = sum(new_mask(:) == 1);
                if valid_p > 0
                    HC_GOAL{i, k}(j, :) = HC_GOAL{i, k}(j, :) ./ valid_p;
                end
            end
        end
    end
end

cerror = 0;
hc_test = cell(n_bins_dist, 1);
hc_test(:) = {zeros(3, 255)}; % Preallocate the memory for the histograms

for i=1:numel(goal_imgs)
    
    for j=1:3 % For each color channel
        sub_img = test_imgs{i}(:, :, j);
        
        dist_img = ones(size(sub_img));
        dist_img(img_mask{i}) = 0; % Set inside of the goal mask to 0
        
        % Compute the distance of all the zero pixels to the closest 1
        % pixels, i.e. distance to the edge for each pixel
        dist_img = bwdist(dist_img);
        d_bin = discretize(dist_img, EDGESD{i});
        
        % For each distance bin compute a color histogram
        for k=1:n_bins_dist
            
            % Get a new mask than only has the pixels within the current
            % distance.
            new_mask = img_mask{i} & (d_bin == k);
            hc_test{k}(j, :) = histcounts( sub_img(new_mask), edges);
            
            % Normalize by the number of valid pixels
            valid_p = sum(new_mask(:) == 1);
            if valid_p > 0
                hc_test{k}(j, :) = hc_test{k}(j, :) ./ valid_p;
            end
        end
    end
    
    % For each distance bin compute the error
    for k=1:n_bins_dist
        cerror = cerror + (sum(abs(hc_test{k}(1, :) - HC_GOAL{i, k}(1, :))) + ...
            sum(abs(hc_test{k}(2, :) - HC_GOAL{i, k}(2, :))) + ...
            sum(abs(hc_test{k}(3, :) - HC_GOAL{i, k}(3, :)))) / 6;
    end
end

% Divide by the number of images and by the number of distance bins so that
% the error function is still in the range of 0..1
cerror = cerror ./ (numel(goal_imgs) * n_bins_dist);

end
