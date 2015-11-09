#!/usr/bin/env ruby

require 'socket'

# maxRetries * 0.1 = number of seconds waiting for Maya to load
maxRetries = 300
timesFailed = 0

while timesFailed <= maxRetries do
	begin
		mel = STDIN.read

		s = TCPSocket.open("localhost", 2222)

		s.puts(mel)

		mayaReturn = s.gets()
		
		exit(0)
	rescue Errno::ECONNREFUSED
		timesFailed += 1
		# Maya is not ready yet, wait a bit before retrying
		sleep(0.1)
	end
end

exit(-1)
