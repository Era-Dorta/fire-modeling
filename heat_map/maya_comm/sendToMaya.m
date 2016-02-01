function sendToMaya( sendScript, port, command, isRender, mrLogPath)
% Sends a command to an open Maya instance
if nargin < 3 || nargin == 4
    % It can be called with just the first three arguments or all of them
    error('Not enough input arguments.')
end

if nargin == 3
    isRender = 0;
end

[status, result] = system([sendScript ' ' num2str(port) ' "' command ';" ' ...
    num2str(isRender) ' < /dev/null']);

if(status ~= 0)
    if(isRender)
        % On error save the output in a MentaRay log file
        fileId = fopen(mrLogPath, 'w');
        fprintf(fileId, '%s', result);
        fclose(fileId);
        error(['Could not render image, check Mental Ray log in ' mrLogPath]);
    else
        error('Could not execute command, is Maya open?');
    end
end
end

