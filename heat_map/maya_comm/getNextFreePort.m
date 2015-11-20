function [ port ] = getNextFreePort()
% Returns a port that is not in use
port = 2222;
% The -b option should avoid infinite waits under certain situations
[~,result] = system(['lsof -b -i:' num2str(port)]);
while(~isempty(result))
    port = port + 1;
    [~,result] = system(['lsof -b -i:' num2str(port)]);
end
end