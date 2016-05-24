function [ out_color ] = getColorFromHistoIndex( in_idx, n_bins, bin_width)
%GETCOLORFROMHISTOINDEX Returns color from histogram
%   [ OUT_COLOR ] = GETCOLORFROMHISTOINDEX( IN_IDX, N_BINS, BIN_WIDTH)
%   IN_IDX is a matrix of indices that correspond to a histogram computed
%   with histogram getImgCombinedHistogram, using N_BINS and with
%   BIN_WIDTH. This function returns in OUT_COLOR the corresponding RGB or
%   (or other color space) values for the given indices.
%
%   See also getImgCombinedHistogram

out_color = zeros(size(in_idx, 1), size(in_idx, 2), 3);

int_n_bins = int64(n_bins);

% Store as int for idivide, as the indices go from 1:n_bins^3, but the
% base for the numeric base tranformation we need them in 0:n_bins^3 -1
% We assume the indices are ints so there are no rounding errors
remColor = int64(in_idx - 1);

% Red, n_bins^0
out_color(:,:,1) = mod(remColor, int_n_bins);

remColor = idivide(remColor, int_n_bins, 'floor');

% Green, n_bins^1
out_color(:,:,2) = mod(remColor, int_n_bins);

% Blue, n_bins^2
out_color(:,:,3) = idivide(remColor, int_n_bins, 'floor');

%% Tranform from bin_index to RGB color
out_color = double(out_color * bin_width + bin_width / 2);

end

