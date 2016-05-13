function sendToMaya( sendScript, port, command, isRender)
% Sends a command to an open Maya instance
if nargin < 3
    % It can be called with just the first three arguments or all of them
    error('Not enough input arguments.')
end

if nargin == 3
    isRender = 0;
end

[status, result] = system([sendScript ' ' num2str(port) ' "' command ';" ' ...
    num2str(isRender) ' < /dev/null']);

if(status ~= 0)
    if isequal(result, sprintf('\n'))
        result = '\n';
    end
    error(['Could not execute command ''' command ''' in Maya:' num2str(port) ...
        sprintf('\nMaya output was "') result '"' ...
        sprintf('\nSee MayaLogs in the output folder for more information')]);
end


