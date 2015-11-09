function closeMayaAndMoveMRLog( logNewPath )
% close Maya
cmd = 'quit -f';
sendToMaya(cmd, sendMayaScript);

if(exist('mentalray.log', 'file'))
    system(['mv mentalray.log ' logNewPath 'mentalray.log']);
end
end

