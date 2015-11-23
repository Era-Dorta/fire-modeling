function save_summary_file( summary_file, opt_method, best_error, ...
    heat_map_size, options, LB, UB, total_time, x0_file )
if nargin < 8
    error('Not enough parameters');
end

% Save a summary file for the genetics algorithm solver
fileId = fopen(summary_file, 'w');
fprintf(fileId, 'Optimization method is %s\n', opt_method);
fprintf(fileId, 'Image error is %f\n', best_error);
fprintf(fileId, 'Heat map size is %d\n', heat_map_size);
fprintf(fileId, 'Job took %f seconds\n', total_time);
fprintf(fileId, 'Lower bounds is %f\n', LB);
fprintf(fileId, 'Upper bounds is %f\n', UB);

if nargin == 9
    fprintf(fileId, 'Initial guess data was taken from %s\n', x0_file);
end

% Convert options to cell
fields = repmat(fieldnames(options), numel(options), 1);
values = struct2cell(options);

% Convert all the values to strings
values = cell2cellstr(values);

% Combine field names and values in the same array
C = {fields{:}; values{:}};

fprintf(fileId, '%s is %s\n', C{:});
fclose(fileId);
disp(['Summary file saved in ' summary_file]);
end

