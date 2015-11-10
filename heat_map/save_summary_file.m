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

% Numeric values to string
idx = cellfun(@isnumeric, values);
values(idx) = cellfun(@num2str, values(idx), 'UniformOutput', 0);

% Function pointers to string
func_handl_cell = cellstr(repmat('function_handle', size(values,1), 1));
idx = cellfun(@isa, values, func_handl_cell);
values(idx) = cellfun(@func2str, values(idx), 'UniformOutput', 0);
values(idx) = cellfun(@(x) ['@' x], values(idx), 'UniformOutput', 0);

% Logical values to string
tfcell = {'false', 'true'};
idx = cellfun(@islogical, values);
values(idx) = cellfun(@(x)tfcell{x + 1}, values(idx), 'UniformOutput', 0);

% Empty values explicitely to []
idx = cellfun(@isempty, values);
values(idx) = cellfun(@(x)'[]', values(idx), 'UniformOutput', 0);

% Combine field names and values in the same array
C = {fields{:}; values{:}};

fprintf(fileId, '%s is %s\n', C{:});
fclose(fileId);
disp(['Summary file saved in ' summary_file]);
end

