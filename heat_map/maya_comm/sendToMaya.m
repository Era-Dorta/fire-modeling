function sendToMaya( sendScript, port, command, logPath, isRender)
% Sends a command to an open Maya instance
if nargin < 4
    % It can be called with just the first three arguments or all of them
    error('Not enough input arguments.')
end

if nargin == 4
    isRender = 0;
end

[status, result] = system([sendScript ' ' num2str(port) ' "' command ';" ' ...
    num2str(isRender) ' < /dev/null']);

if(status ~= 0)
    % On error save the output in log file
    fileId = fopen(logPath, 'w');
    fprintf(fileId, '%s', result);
    fclose(fileId);
    
    error(['Could not execute command ' cmd ' in Maya:' num2str(port) ...
        ' log file saved in ' logPath]);
end


