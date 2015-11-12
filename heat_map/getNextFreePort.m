function [ port ] = getNextFreePort()
% Returns a port that is not in use
port = 2222;
[~,result] = system(['lsof -i:' num2str(port)]);
while(~isempty(result))
    port = port + 1;
    [~,result] = system(['lsof -i:' num2str(port)]);
end
end