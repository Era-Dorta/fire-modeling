function [ outcell ] = cell2cellstr( incell )
% Converts a the contents of a cell into strings
outcell = incell;

% This function only words for column cells, so if it is a row cell
% transpose it, if it is a matrix, the code will crash
transposed = false;
if(isrow(outcell))
    transposed = true;
    outcell = outcell';
end

% Numeric values to string
idx = cellfun(@isnumeric, outcell);
outcell(idx) = cellfun(@num2str, outcell(idx), 'UniformOutput', 0);

% Function pointers to string
func_handl_cell = cellstr(repmat('function_handle', size(outcell,1), 1));
idx = cellfun(@isa, outcell, func_handl_cell);
outcell(idx) = cellfun(@func2str, outcell(idx), 'UniformOutput', 0);
outcell(idx) = cellfun(@(x) ['@' x], outcell(idx), 'UniformOutput', 0);

% Logical values to string
tfcell = {'false', 'true'};
idx = cellfun(@islogical, outcell);
outcell(idx) = cellfun(@(x)tfcell{x + 1}, outcell(idx), 'UniformOutput', 0);

% Empty values explicitely to []
idx = cellfun(@isempty, outcell);
outcell(idx) = cellfun(@(x)'[]', outcell(idx), 'UniformOutput', 0);

% Fail for struct values in the cell
idx = cellfun(@isstruct, outcell);
assert(sum(idx) == 0, 'cell2cellstr cannot handle structs');

% Recursive call for cell values in the cell
idx = cellfun(@iscell, outcell);
outcell(idx) = cellfun(@(x)cell2cellstr(x), outcell(idx), 'UniformOutput', 0);
outcell(idx) = cellfun(@strjoin, outcell(idx), 'UniformOutput', 0);

% Transpose again for coherence with the input
if(transposed)
    outcell = outcell';
end
end

