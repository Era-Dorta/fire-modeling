function [ outheapmap ] = resampleHeatMap( inheatmap, newsize )
% Resamples the heat map to the input dimension

%% Prepare the data for interp3
% Compute a dense copy of the XYZ and the V values, this horribly bad for
% memory usage, but that is the format required for interp3

% Compute a dense copy of the XYZ and the V values
[X, Y, Z] = meshgrid(1:inheatmap.size(1), 1:inheatmap.size(2), 1:inheatmap.size(3));
V = zeros(inheatmap.size(1), inheatmap.size(2), inheatmap.size(3));
singleind = sub2ind(size(V), inheatmap.xyz(:,1), inheatmap.xyz(:,2), inheatmap.xyz(:,3));
V(singleind) = inheatmap.v;

% Compute the new indices
XYZnew(:, 1) = round(fitToRange(inheatmap.xyz(:,1), 1, inheatmap.size(1), 1, newsize(1)));
XYZnew(:, 2) = round(fitToRange(inheatmap.xyz(:,2), 1, inheatmap.size(2), 1, newsize(2)));
XYZnew(:, 3) = round(fitToRange(inheatmap.xyz(:,3), 1, inheatmap.size(3), 1, newsize(3)));

% Delete the repeated ones
XYZnew = unique(XYZnew, 'rows');

% Get the new indices in the old index space
XYZq(:, 1) = fitToRange(XYZnew(:,1), 1, newsize(1), 1, inheatmap.size(1));
XYZq(:, 2) = fitToRange(XYZnew(:,2), 1, newsize(2), 1, inheatmap.size(2));
XYZq(:, 3) = fitToRange(XYZnew(:,3), 1, newsize(3), 1, inheatmap.size(3));

%% Interpolate the data
% We have linear, cubic and spline interpolation, cubic is fast enough that
% we can use it
Vq = interp3(X, Y, Z, V, XYZq(:,1), XYZq(:,2), XYZq(:,3), 'cubic');

%% Build the output
outheapmap = struct('xyz', XYZnew, 'v', Vq, 'size', newsize, ...
    'count', size(XYZnew, 1));
end

