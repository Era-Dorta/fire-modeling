%test upHeatEstimate

% Tolerance for float comparison
tol = 0.00001;

% Set by default a 3x3x3 volume for all tests
xyz = [1 1 1;
    1 1 2;
    1 1 3;
    1 2 1;
    1 2 2;
    1 2 3;
    1 3 1;
    1 3 2;
    1 3 3;
    2 1 1;
    2 1 2;
    2 1 3;
    2 2 1;
    2 2 2;
    2 2 3;
    2 3 1;
    2 3 2;
    2 3 3;
    3 1 1;
    3 1 2;
    3 1 3;
    3 2 1;
    3 2 2;
    3 2 3;
    3 3 1;
    3 3 2;
    3 3 3];

volumeSize = [3, 3, 3];
v = zeros(1,27);

%% Test one voxel, no upheat

xyz = [1, 1, 1];
v = 1;
volumeSize = [1, 1, 1];

upheatv = upHeatEstimate( xyz, v, volumeSize );

expec_upheatv = 0;

assert(abs(expec_upheatv - upheatv) < tol, 'Failed upheat with one voxel');

%% Test one voxel, value 0, upheat 1

xyz = [1, 1, 1];
v = 0;
volumeSize = [1, 1, 1];

upheatv = upHeatEstimate( xyz, v, volumeSize );

expec_upheatv = 1;

assert(abs(expec_upheatv - upheatv) < tol, 'Failed upheat with one voxel');

%% Test 3x3x3 volume, center increasing

coord = [2 1 2; 2 2 2; 2 3 2];
v = [1, 2, 4] ;

upheatv = upHeatEstimate( coord, v, volumeSize );

expec_upheatv = 2/3;

assert(abs(expec_upheatv - upheatv) < tol, 'Failed upheat with 3x3x3 volume, 3 voxels up');

%% Test 3x3x3 volume

v(1:3) = [1, 2, 3]; % 2 up
v(4:6) = [3, 2, 1]; % 2 up
v(7:9) = [1, 2, 3];

v(10:12) = [1, 1, 1]; % 3 up
v(13:15) = [2, 2, 2]; % 0 up
v(16:18) = [1, 1, 1];

v(19:21) = [4, 5, 6]; % 3 up
v(22:24) = [4, 5, 6]; % 1 up
v(25:27) = [7, 1, 2];

upheatv = upHeatEstimate( xyz, v, volumeSize );

expec_upheatv = 11/27;

assert(abs(expec_upheatv - upheatv) < tol, 'Failed upheat with 3x3x3 volume');