function append_to_summary_file( summary_file, data )
%APPEND_TO_SUMMARY_FILE Adds data to a text file
%   APPEND_TO_SUMMARY_FILE( SUMMARY_FILE, DATA ) appends DATA to the text
%   file in SUMMARY_FILE path. DATA must be a string.
summary_file = [summary_file '.txt'];

fileId = fopen(summary_file, 'a');

if(fileId ~= -1)
    closeFileObj = onCleanup(@() fclose(fileId));
else
    ME = MException('MATLAB:append_to_summary_file', ...
        'Cannot open file %s.', summary_file);
    throw(ME);
end

fprintf(fileId, '%s\n', data);

end

