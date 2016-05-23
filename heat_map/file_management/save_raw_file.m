function save_raw_file( filePath, volumetricData )
%SAVE_RAW_FILE Save a dataset to a .raw file
%   SAVE_RAW_FILE(FILEPATH, VOLUMETRICDATA) saves the VOLUMETRICDATA raw
%   struct data in the path FILEPATH

if(exist(filePath, 'file'))
    warning(['File "' filePath '" exists, avoiding overwrite.']);
    return;
end

fileID = fopen(filePath,'w');

if(fileID ~= -1)
    fileCloseObj = onCleanup(@() fclose(fileID));
else
    error('Cannot open file %s.', filePath);
end

fwrite(fileID, volumetricData.size, 'int32');
fwrite(fileID, volumetricData.count, 'int32');

% Revert to 0...256 range and add 0 to have rgba values
volZeros = zeros(volumetricData.count, 1);
rgba = [volumetricData.v  * 256, volZeros , volZeros, volZeros + 1];

% Flip y and z
volumetricData.xyz = [volumetricData.xyz(:, 1), volumetricData.xyz(:, 3), ...
    volumetricData.xyz(:, 2)];

for i=1:volumetricData.count
    fwrite(fileID, volumetricData.xyz(i,:), 'int32');
    fwrite(fileID, rgba(i,:), 'double');
end

end

