function Mean_Square_Error= MSEPerceptual(Reference_Image, Target_Image, ...
    reference_mask, target_mask)
%MSEPERCEPTUAL MSE using color
%   MEAN_SQUARE_ERROR= MSEPERCEPTUAL(REFERENCE_IMAGE, TARGET_IMAGE, ...
%    REFERENCE_MASK, TARGET_MASK)
%
%   See also MSE

Mean_Square_Error = 0;

for i=1:numel(Reference_Image)
    assert(all(size(Reference_Image{i}) == size(Target_Image{i})));
    
    valid_pixels = sum(reference_mask{i}(:));
    
    assert(sum(target_mask{i}(:)) == valid_pixels);
    
    % Multiply by the mask
    Reference_Image{i} = bsxfun(@times, double(Reference_Image{i}), reference_mask{i});
    Target_Image{i} = bsxfun(@times, double(Target_Image{i}), target_mask{i});
    
    % Compute the norm for each pixel using the 3 colors
    error_image = (Reference_Image{i} - Target_Image{i}).^2;    
    error_image = sqrt(error_image(:,:,1) + error_image(:,:,2) + error_image(:,:,3));
    
    Mean_Square_Error = Mean_Square_Error + sum(error_image(:)) / valid_pixels;
end

% Normalize by the number of goal images
Mean_Square_Error = Mean_Square_Error ./ numel(Reference_Image);

assert(all(~isinf(Mean_Square_Error)), 'X contains Inf');
assert(all(~isnan(Mean_Square_Error)), 'X contains NaN');
assert(all(Mean_Square_Error >= 0), 'X is < 0');

end


