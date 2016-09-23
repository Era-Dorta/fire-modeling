function Mean_Square_Error= MSEPerceptualExp(Reference_Image, Target_Image, ...
    reference_mask, target_mask)
%MSEPERCEPTUALEXP MSE using color
%   MEAN_SQUARE_ERROR= MSEPERCEPTUALEXP(REFERENCE_IMAGE, TARGET_IMAGE, ...
%    REFERENCE_MASK, TARGET_MASK) Computes error as in MSEPerceptual, but
%    it exponentiates the result.
%
%   See also MSEPerceptual

Mean_Square_Error = exp(MSEPerceptual(Reference_Image, Target_Image, ...
    reference_mask, target_mask));
end

