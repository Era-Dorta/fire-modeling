function [ bb_data ] = read_bbdata( file_path )
%READ_BBDATA Loads black body data from file
%   BB_DATA = READ_BBDATA(FILE_PATH) FILE_PATH must be a text file where
%   each row contains 4 integers separated by spaces. The first value
%   denotes the temperature in kelvin and the rest indicate the colour in
%   [0..255] RGB space. BB_DATA is a Nx4 matrix with the values in the file

fid = fopen(file_path);

fileCloseObj = onCleanup(@() fclose(fid));

% fscanf reads in column order, transpose to row order
bb_data = fscanf(fid, '%d %d %d %d\n', [4 Inf])';
end

