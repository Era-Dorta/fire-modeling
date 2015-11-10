function status = sendToMaya( command, sendScript, isRender)
% Sends a command to an open Maya instance
if nargin < 3
    isRender = 0;
end
status = system([sendScript ' "' command ';" ' num2str(isRender)]);
status = status == 0;
end

