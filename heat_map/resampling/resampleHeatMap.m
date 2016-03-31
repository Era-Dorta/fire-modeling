function [ outheapmap ] = resampleHeatMap( inheatmap, mode,  XYZnew)
% Resamples the heat map, either by half or by double the size

if strcmp(mode,'up')
    % Upsample the volume
    newsize = inheatmap.size * 2;
else
    if strcmp(mode,'down')
        % Down sample the volume
        newsize = round(inheatmap.size / 2);
    else
        error('mode must be "up" or "down"');
    end
end

%% Prepare the data for interp3
% Compute a dense copy of the XYZ and the V values, this horribly bad for
% memory usage, but that is the format required for interp3

% X is a size^3 matrix which contains all the X corrdinates in the grid,
% and the same with Y and Z
[X,Y,Z] = meshgrid(1:inheatmap.size(1),1:inheatmap.size(2),1:inheatmap.size(3));

% Get a dense copy of V
V = zeros(inheatmap.size(1), inheatmap.size(2), inheatmap.size(3));
vInd = sub2ind(inheatmap.size, inheatmap.xyz(:,1), inheatmap.xyz(:,2), inheatmap.xyz(:,3));
V(vInd) = inheatmap.v;

% Compute the new indices of newsize
[Xnew, Ynew, Znew] = meshgrid(1:newsize(1),1:newsize(2),1:newsize(3));
% Put them in a vector so we can index them easily afterwards
Xnew = Xnew(:);
Ynew = Ynew(:);
Znew = Znew(:);

% Get the new indices in the old index space, we are going to query all the
% points in the new space in the old space, this is quite wastefull but we
% don't have to worry about how to generate the query points efficiently

% The 0.5 displacements are needed to get the right coordinates as we
% assume that the index represents the voxel value in the middle of the
% voxel, e.g. old size 1..4, new size 1..2, without displacement query
% points are 1 and 4, but they should be 1.5 and 3.5
Xq = fitToRange(Xnew, 0.5, newsize(1) + 0.5, 0.5, inheatmap.size(1) + 0.5);
Yq = fitToRange(Ynew, 0.5, newsize(2) + 0.5, 0.5, inheatmap.size(2) + 0.5);
Zq = fitToRange(Znew, 0.5, newsize(3) + 0.5, 0.5, inheatmap.size(3) + 0.5);

%% Interpolate the data
% We have linear, cubic and spline interpolation, cubic and spline can
% output negative temperatures, so for our case it is better to use linear
Vq = interp3(X, Y, Z, V, Xq, Yq, Zq, 'linear', 0);

%% Build the output

if nargin == 2
    % Get the non zero values
    nonzeroInd = find(Vq ~= 0);
    Vq = Vq(nonzeroInd);
    XYZnew = [Ynew(nonzeroInd), Xnew(nonzeroInd), Znew(nonzeroInd)];
else
    % Get the values given by the user
    Vq = Vq(sub2ind(newsize, XYZnew(:,1), XYZnew(:,2), XYZnew(:,3)));
end

outheapmap = struct('xyz', XYZnew, 'v', Vq, 'size', newsize, 'count', ...
    size(XYZnew, 1));
end

