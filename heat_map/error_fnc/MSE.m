function Mean_Square_Error= MSE(Reference_Image, Target_Image, ...
    reference_mask, target_mask)

% Takes two images (2D) and returns Mean Square Error
% Be aware Matrix dimensions must agree

% written by Amir Pasha Mahmoudzadeh
% Wright State University
% Biomedical Imaging Lab
Mean_Square_Error = 0;

for i=1:numel(Reference_Image)
    assert(all(size(Reference_Image{i}) == size(Target_Image{i})));
    
    % Make the masks RGB if they are for a single channel
    if(size(reference_mask{i}, 3) < 3)
        reference_mask{i}(:, :, 2) = reference_mask{i}(:, :, 1);
        reference_mask{i}(:, :, 3) = reference_mask{i}(:, :, 1);
    end
    
    if(size(target_mask{i}, 3) < 3)
        target_mask{i}(:, :, 2) = target_mask{i}(:, :, 1);
        target_mask{i}(:, :, 3) = target_mask{i}(:, :, 1);
    end
    
    Reference_Image{i} = double(Reference_Image{i}(reference_mask{i}));
    Target_Image{i} = double(Target_Image{i}(target_mask{i}));
    
    [M, N] = size(Reference_Image{i});
    error = Reference_Image{i} - Target_Image{i};
    Mean_Square_Error = Mean_Square_Error + sum(sum(error .* error)) / (M * N);
end

% Normalize by the number of goal images and by the maximum difference
% squared (pixels are in the range of 0..255) so that the error goes from
% 0 to 1
Mean_Square_Error = Mean_Square_Error ./ (numel(Reference_Image) * 255^2);

assert_valid_range_in_0_1(Mean_Square_Error);

end


