function status = sendToMaya( sendScript, port, command, isRender)
% Sends a command to an open Maya instance
if nargin < 4
    isRender = 0;
end
status = system([sendScript ' ' num2str(port) ' "' command ';" ' num2str(isRender)]);
status = status == 0;
end

