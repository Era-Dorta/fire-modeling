function retval = isCommandWindowOpen()
    jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
    retval = ~isempty(jDesktop.getClient('Command Window'));
end