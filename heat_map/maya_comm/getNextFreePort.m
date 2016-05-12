function [ port ] = getNextFreePort(init_port)
% Returns a port that is not in use
port = 2222;
if nargin == 1
    port = init_port;
end
while(system(['nc -z localhost ' num2str(port)]) == 0)
    port = port + 1;
end
end