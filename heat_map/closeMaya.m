function closeMaya(sendMayaScript, port)
% close Maya
cmd = 'quit -f';
if(~sendToMaya(sendMayaScript, port, cmd))
    warning('Could not close Maya, please do it manually');
end
end

