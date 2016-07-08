function new_bg = bg_completion(img, mask, bg_full, use_simple, do_plots)
%BG_COMPLETION Fill gaps in background image
%   NEW_BG = BG_COMPLETION(IMG, MASK, BG_FULL)
%   Given an image IMG with a gap to fill given by MASK, and the
%   same image under different illumination BG_FULL. A new image NEW_BG is
%   generated with the parts in IMG filled with BG_FULL, where
%   BG_FULL colors have been corrected to match the ~MASK parts in
%   IMG. MASK is a NxM matrix of logical or a double.
%
%   NEW_BG = BG_COMPLETION(IMG, MASK, BG_FULL, USE_SIMPLE, DO_PLOTS)
%   USE_SIMPLE will use simple constant matching for the colors, default is
%   false. DO_PLOTS will plot the inputs and results, default is false.
%

% Check sizes of images
assert(all(size(img) == size(bg_full)));
assert(size(img, 1) == size(mask, 1) && ...
    size(img, 2) == size(mask, 2));
assert(size(mask, 3) == 1);

if nargin < 5
    do_plots = false;
    if nargin < 4
        use_simple = false;
    end
end

new_bg = zeros(size(bg_full));
new_bg_inside = zeros(size(bg_full));

if islogical(mask)
    mask = double(mask);
end

if ~isfloat(mask)
    mask = double(mask) / 255;
end

mask = 1 - mask;

bg_missing = bsxfun(@times, double(img), mask);

for i=1:size(bg_missing, 3)
    bg_missing1 = bg_missing(:,:,i);
    bg_full1 = double(bg_full(:,:,i));
    
    if use_simple
        % Get light variation between both images for the known part
        diff_light_out = bg_full1 .* mask - bg_missing1 .* mask;
        
        % Compute the mean variation, hopefully the standard deviation is
        % small
        mean_out = sum(diff_light_out(:)) ./ sum(mask(:));
        
        % Make the full background have the same color as the missing one
        bg_full1 = bg_full1 - mean_out;
        
        % Save just the new filling for plotting
        new_bg_inside(:,:,i) = bg_full1 .* (1 - mask);
        
        % Built the combination using both backgrounds
        new_bg(:,:,i) = bg_missing1 .* mask + new_bg_inside(:,:,i);
    else
        % Get light variation for the known and the unknown parts
        diff_light_out = bg_full1 .* mask - bg_missing1 .* mask;
        diff_light_in = bg_full1 .* (1 - mask) - bg_missing1 .* (1 - mask);
        
        % Get mean difference for both missing and known
        mean_out = sum(diff_light_out(:)) ./ sum(mask(:));
        mean_in = sum(diff_light_in(:)) ./ sum(1 - mask(:));
        
        assert(mean_in > 0, 'bg_missing1 missing values must be black');
        
        % Make the unkown difference map have the same mean as the known
        diff_light_in = diff_light_in/mean_in * mean_out;
        
        % Put together the unknown and known differences
        diff_light = diff_light_in + diff_light_out;
        
        % New background is the full one sifted to the new missing one
        % using the differences
        new_bg(:,:,i) = bg_full1 - diff_light;
        
        % Save just the new filling for plotting
        new_bg_inside(:,:,i) = new_bg(:,:,i) .* (1 - mask);
    end
end

new_bg = uint8(new_bg);

if do_plots
    n_row = 2;
    n_col = 3;
    c_fig = 1;
    
    bg_missing = uint8(bg_missing);
    new_bg_inside = uint8(new_bg_inside);
    
    figure;
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(img);
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(bg_full);
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(1 - mask);
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(bg_missing);
    subtightplot(n_row,n_col,c_fig); c_fig = c_fig + 1; imshow(new_bg_inside);
    subtightplot(n_row,n_col,c_fig); imshow(new_bg);
end

end