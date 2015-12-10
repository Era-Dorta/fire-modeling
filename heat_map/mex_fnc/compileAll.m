% Script that compiles all the files in the mex_fnc folder

% Go into current folder as we are giving mex relative file paths
cdir = pwd;
cd(fileparts(mfilename('fullpath')));

mex mixHeatMaps.cpp createVoxelDataSet.cpp -lopenvdb -lHalf -ltbb  -L/usr/lib/x86_64-linux-gnu/ -L/usr/include/

% Return to previous folder
cd(cdir); 