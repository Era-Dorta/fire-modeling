function [ cerror ] = histogramError( imga, imgb, ignore_black )
% Computes an error measure between two images using their histograms
if nargin == 2
    ignore_black = false;
end

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

isrgb = true;
if(size(imga, 3) == 1)
    isrgb = false;
end

% If histcounts exist use it, for older Matlab versions, 2014 and previous
% we have to use histc
if exist('histcounts', 'file') == 2
    histcounts_foo = @histcounts;
else
    histcounts_foo = @histc;
    
    % histc will return a matrix instead of a vector, so reshape the images
    % to one vector for each color channel
    imga = reshape(imga, size(imga, 1) * size(imga, 2), 1, size(imga, 3));
    imgb = reshape(imgb, size(imgb, 1) * size(imgb, 2), 1, size(imgb, 3));
end

% Compute the histogram count for each color channel
Na(1, :) = feval(histcounts_foo, imga(:, :, 1), edges);
Nb(1, :) = feval(histcounts_foo, imgb(:, :, 1), edges);

if isrgb
    Na(2, :) = feval(histcounts_foo, imga(:, :, 2), edges);
    Na(3, :) = feval(histcounts_foo, imga(:, :, 3), edges);
    
    Nb(2, :) = feval(histcounts_foo, imgb(:, :, 2), edges);
    Nb(3, :) = feval(histcounts_foo, imgb(:, :, 3), edges);
end

if ignore_black
    % The first bin is for black, so ignore it
    bin_range = 2:size(Na, 2);
else
    bin_range = 1:size(Na, 2);
end

% Compute the error as the norm of the bin vector for each color channel
cerror(1) = norm(Na(1, bin_range) - Nb(1, bin_range));

if isrgb
    cerror(2) = norm(Na(2, bin_range) - Nb(2, bin_range));
    cerror(3) = norm(Na(3, bin_range) - Nb(3, bin_range));
end

end
