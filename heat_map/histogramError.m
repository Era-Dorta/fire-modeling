function [ cerror ] = histogramError( imga, imgb, ignore_black )
% Computes an error measure between two images using their histograms

% Create 256 bins, image can be 0..255 or 0..1
if isfloat(imga) && isfloat(imgb)
    edges = linspace(0, 1, 256);
else
    if ~isfloat(imga) && ~isfloat(imgb)
        edges = linspace(0, 255, 256);
    else
        error('Both images need to be in the same format');
    end
end
Na = histcounts(imga, edges);
Nb = histcounts(imgb, edges);
if ignore_black
    % The first bin is for black, so ignore it
    cerror = norm(Na(2:end) - Nb(2:end));
else
    cerror = norm(Na - Nb);
end
end
