%test combineHeatMap8

% To be able to run this tests define the RUN_TESTS macro in 
% combineHeatMap8.cpp and recompile the code, the macro disables the
% randomness is the function

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
v = combineHeatMap8(xyz, v0, v1, min(xyz, [], 1), max(xyz, [], 1), 0.5);

% Test that each voxel belongs to the corresponding heatmap or mean of them
assert(all(abs(v - v0) < tol), 'combineHeatMap8 does not reproduce heatmap coordinates order');

%% Test expected output with 3x3 heatmaps, 0.5 interpolation

% Create two random 3x3 heatmaps
v0 = rand(27, 1);
v1 = rand(27, 1);

vmean = (v0 + v1) / 2;

% Combine the voxels
v = combineHeatMap8(xyz, v0, v1, min(xyz, [], 1), max(xyz, [], 1), 0.5);

% Test
assert(all(abs(v - vmean) < tol), 'combineHeatMap8 wrong values in the boundaries');

%% Test expected output with 3x3 heatmaps, 0.8 interpolation

% Create two random 3x3 heatmaps
v0 = rand(27, 1);
v1 = rand(27, 1);

v0_out = v0 * 0.8 + v1 * 0.2;
v1_out = v0 * 0.2 + v1 * 0.8;
vmean_out = v0 * 0.5 + v1 * 0.5;

% Indices of each input voxel in the output
idxv0 = [1, 9, 21, 25];
idxv1 = [3, 7, 19, 27];

% Indices for the mean input voxels in the output
idxmean = 1:27;
idxmean([idxv0, idxv1]) = [];

% Combine the volumes
v = combineHeatMap8(xyz, v0, v1, min(xyz, [], 1), max(xyz, [], 1), 0.8);

% Test that each voxel belongs to the corresponding heatmap or mean of them
val_match = all(abs(v(idxv0) - v0_out(idxv0)) < tol) && all(abs(v(idxv1) - v1_out(idxv1)) < tol);
assert(val_match, 'combineHeatMap8 wrong values inside the bounding boxes');

val_match = all(abs(v(idxmean) - vmean_out(idxmean)) < tol);
assert(val_match, 'combineHeatMap8 wrong values in the boundaries');
