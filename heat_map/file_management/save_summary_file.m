function save_summary_file( summary_file, summary_data, options )
% Save a summary file for the optimization method

%Put the fields in alphabetic order for easy comparisong
summary_data = orderfields(summary_data);

% Save the data in a mat file
if isempty(options)
    save([summary_file '.mat'], 'summary_data');
else
    options = orderfields(options);
    save([summary_file '.mat'], 'summary_data', 'options');
end

% Also save it in a text file
summary_file = [summary_file '.txt'];

fileId = fopen(summary_file, 'w');

if(fileId ~= -1)
    closeFileObj = onCleanup(@() fclose(fileId));
else
    ME = MException('MATLAB:save_summary_file', 'Cannot open file %s.', ...
        summary_file);
    throw(ME);
end

% Print first the optimization method, then the rest of the parameters
fprintf(fileId, 'OptimizationMethod is %s\n', summary_data.OptimizationMethod);

% Delete the field so it doesn't get printed twice
summary_data = rmfield(summary_data, 'OptimizationMethod');

%% Save the general optimization parameters

% Convert summary_data struct to cellstr
C = struct2cellstr(summary_data);

fprintf(fileId, '%s is %s\n', C{:});

%% Save the other options for the algorithm

if ~isempty(options)
    % Convert options struct to cellstr
    C = struct2cellstr(options);
    
    fprintf(fileId, '%s is %s\n', C{:});
end

%% Close the file and give the user some info

disp(['Summary file saved in ' summary_file]);
end

