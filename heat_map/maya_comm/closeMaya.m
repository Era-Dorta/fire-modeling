function closeMaya(sendMayaScript, port)
% close Maya
cmd = 'quit -f';
try
    sendToMaya(sendMayaScript, port, cmd);
    disp(['Maya:' num2str(port) ' closed']);
catch
    warning(['Could not close Maya:' num2str(port) ' , please do it manually']);
end
end

