function compileAll()
%COMPILEALL compile mex files
%   Script that compiles all the files in the mex_fnc folder

% Go into current folder as we are giving mex relative file paths
cdir = pwd;
cd(fileparts(mfilename('fullpath')));

% The name of each .cpp file that we would like to compile
fncNames = {'combineHeatMap8.cpp'};

% Common source files for each function
commonSrc = {'createVoxelDataSet.cpp'};

% Libraries header folders
libs_inc = {'-I/usr/include/'};

% Linking libraries
libs = {'-lopenvdb', '-lHalf', '-ltbb'};

% Libraries search path
libs_path = {'-L/usr/lib/x86_64-linux-gnu', '-L/usr/lib'};

for i = 1:numel(fncNames)
    % Clear all the functions from memory, if we are compiling after a change
    % in the code, this ensures that the new version will be used
    [~, nameNoExt, ~] = fileparts(fncNames{i});
    clear(nameNoExt);
    
    % Compile current function
    mex(fncNames{i}, commonSrc{:}, libs_inc{:}, libs_path{:}, libs{:});
end

% Return to previous folder
cd(cdir);

% TODO Move the code to this directory
% Call extra mex file compiling
build_dist_fnc;

build_color_space;
end
