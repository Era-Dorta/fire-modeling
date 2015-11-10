function save_raw_file( filePath, volumetricData )
% Save a dataset to a .raw file
fileID = fopen(filePath,'w');

fwrite(fileID, volumetricData.size, 'int32');

% Revert to 0...256 range and add 0 to have rgba values
volZeros = zeros(volumetricData.size, 1);
rgba = [volumetricData.v  * 256, volZeros , volZeros, volZeros + 1];

for i=1:volumetricData.size
    fwrite(fileID, volumetricData.xyz(i,:), 'int32');
    fwrite(fileID, rgba(i,:), 'double');
end

fclose(fileID);
end

