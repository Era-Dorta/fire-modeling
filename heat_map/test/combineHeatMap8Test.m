%test combineHeatMap8

% Tolerance for float comparison
tol = 0.00001;

xyz = [0 0 0;
    0 0 1;
    0 0 2;
    0 1 0;
    0 1 1;
    0 1 2;
    0 2 0;
    0 2 1;
    0 2 2;
    1 0 0;
    1 0 1;
    1 0 2;
    1 1 0;
    1 1 1;
    1 1 2;
    1 2 0;
    1 2 1;
    1 2 2;
    2 0 0;
    2 0 1;
    2 0 2;
    2 1 0;
    2 1 1;
    2 1 2;
    2 2 0;
    2 2 1;
    2 2 2];

%% Test expected output with 3x3 heatmaps with the same values

% Create two random 3x3 heatmaps
v0 = rand(27, 1);
v1 = v0;

% Combine the voxels
v = combineHeatMap8(xyz, v0, v1, min(xyz, [], 1), max(xyz, [], 1));

% Test that each voxel belongs to the corresponding heatmap or mean of them
assert(all(abs(v - v0) < tol), 'combineHeatMap8 does not reproduce heatmap coordinates order');

%% Test expected output with 3x3 heatmaps

% Create two random 3x3 heatmaps
v0 = rand(27, 1);
v1 = rand(27, 1);

vmean = (v0 + v1) / 2;

% Indices of each original voxel in the output
idxv0 = [1, 9, 21, 25];
idxv1 = [3, 7, 19, 27];

% Indices for the mean values
idxmean = 1:27;
idxmean([idxv0, idxv1]) = [];

% Combine the voxels
v = combineHeatMap8(xyz, v0, v1, min(xyz, [], 1), max(xyz, [], 1));

% Test that each voxel belongs to the corresponding heatmap or mean of them
% As there are two randomly choosen ways to combine the heatmaps, test both
first_case = all(abs(v(idxv0) - v0(idxv0)) < tol) && all(abs(v(idxv1) - v1(idxv1)) < tol);
second_case = all(abs(v(idxv1) - v0(idxv1)) < tol) && all(abs(v(idxv0) - v1(idxv0)) < tol);

assert(first_case || second_case, 'combineHeatMap8 wrong values inside the bounding boxes');
assert(all(abs(v(idxmean) - vmean(idxmean)) < tol), 'combineHeatMap8 wrong values in the boundaries');