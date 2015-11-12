function closeMaya(sendMayaScript, port)
% close Maya
cmd = 'quit -f';
try
    sendToMaya(sendMayaScript, port, cmd);
catch
    warning('Could not close Maya, please do it manually');
end
end

