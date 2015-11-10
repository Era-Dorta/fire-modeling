function closeMaya(sendMayaScript)
% close Maya
cmd = 'quit -f';
sendToMaya(cmd, sendMayaScript);
end

