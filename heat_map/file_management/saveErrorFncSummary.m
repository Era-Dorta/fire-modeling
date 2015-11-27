function saveErrorFncSummary( summary_file, summary_data )
% Writes an error function summary file to the destination given as
% parameter

% Save the data in a mat file
save([summary_file '.mat'], 'summary_data');

% Also save it in a text file
summary_file = [summary_file '.txt'];

fileId = fopen(summary_file, 'w');

try
    fprintf(fileId, 'Error function exploration\n');
    
    % Convert summary_data struct to cellstr
    C = struct2cellstr(summary_data);
    
    fprintf(fileId, '%s is %s\n', C{:});
    
catch ME
    fclose(fileId);
    rethrow(ME);
end

%% Close the file and give the user some info
fclose(fileId);
disp(['Summary file saved in ' summary_file]);

end
