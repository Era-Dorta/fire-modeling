function [ hm ] = get_init_heat_map( opts )
%GET_INIT_HEAT_MAP Read heat map
%   [ HM ] = GET_INIT_HEAT_MAP( OPTS ) reads heatmap from OPTS structure
%   and orders the values in ascending order y > z > x

hm = read_raw_file(fullfile(opts.project_path,opts.raw_file_path));
hm.v = hm.v * opts.raw_temp_scale + opts.raw_temp_offset;

% Get linear indices from xzy, so order them by y -> z -> x
lin_idx = sub2ind(hm.size, hm.xyz(:,1), hm.xyz(:,3), hm.xyz(:,2));
[~, ordered_idx] = sort(lin_idx);

hm.v = hm.v(ordered_idx);

hm.xyz = hm.xyz(ordered_idx,:);

if opts.use_prev_frame
    prev_hm = read_raw_file(fullfile(opts.project_path,opts.prev_frame_raw_file_path));
    
    % Initialize with the previous frame using nearest neighbour
    % interpolation and extrapolation
    fs = scatteredInterpolant(prev_hm.xyz(:, 1), prev_hm.xyz(:, 2), ...
        prev_hm.xyz(:, 3), prev_hm.v, 'nearest', 'nearest');
    hm.v = fs(hm.xyz(:, 1), hm.xyz(:, 2), hm.xyz(:, 3));
end

end

