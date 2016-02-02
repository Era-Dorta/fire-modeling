function [ volumetricData ] = read_raw_file( filePath )
%READ_RAW_FILE Read a dataset from a .raw file
%   VOLUMETRICDATA = READ_RAW_FILE(FILEPATH)

fileID = fopen(filePath,'r');

whd = fread(fileID, 3, 'int32');
numPoints = fread(fileID, 1, 'int32');

xyz = zeros(numPoints, 3);
values = zeros(numPoints, 1);

for i=1:numPoints
    xyz(i,:) = fread(fileID, 3, 'int32');
    rgba = fread(fileID, 4, 'double');
    values(i) = max(rgba(1:3)) / 256;
end
fclose(fileID);

volumetricData = struct('xyz', xyz, 'v', values, 'count', numPoints, ...
    'size', whd', 'filename', filePath);
end

