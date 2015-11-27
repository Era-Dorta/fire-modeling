function [ outcellstr ] = struct2cellstr( instruct )
% Converts a struct to a cellstr

outcellstr = {};

fields = repmat(fieldnames(instruct), numel(instruct), 1);
values = struct2cell(instruct);

% Check for structs in the values
idx = cellfun(@isstruct, values);

% Call the function recursivelly for struct in the values
idxs = find(idx);
for i=1:size(idxs, 1)
    
    outcellstr1 = struct2cellstr(values{idxs(i)});
    
    % Append the name of the field to the values
    nameextra = strcat(fields(idxs(i)), '.');
    nameextra = num2cell(repmat(nameextra, 1, size(outcellstr1, 2)));
    outcellstr1(1, :) = cellfun(@strcat, nameextra, outcellstr1(1, :));
    
    % Combine field names and values in the same cell
    outcellstr = {outcellstr{1, :} outcellstr1{1, :}; ...
        outcellstr{2, :} outcellstr1{2, :}};
    
end

% Delete the struct values as we already handled them
fields = fields(~idx);
values = values(~idx);

% Convert all the values to strings
values = cell2cellstr(values);

% Combine field names and values in the same cell
outcellstr = {outcellstr{1, :} fields{:}; outcellstr{2, :} values{:}};

end

