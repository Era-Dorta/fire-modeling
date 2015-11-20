function closeMaya(sendMayaScript, port)
% close Maya
cmd = 'quit -f';
try
    sendToMaya(sendMayaScript, port, cmd);
    disp('Maya closed');
catch
    warning('Could not close Maya, please do it manually');
end
end

