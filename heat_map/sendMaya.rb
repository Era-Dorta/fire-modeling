#!/usr/bin/env ruby

require 'socket'

# maxRetries * 0.1 = number of seconds waiting for Maya to load
maxRetries = 300
timesFailed = 0

if ARGV.size < 1 or ARGV.size > 2
	puts "Usage : sendMaya <maya command>"
	puts "\tOptional second boolean argument fail on return value, default is false"
	exit(0)
end

mel = ARGV[0]
if ARGV.size == 2
	if ARGV[1] == "1" or ARGV[1] == "true"
		failOnreturn = true
	else
		failOnreturn = false
	end
else
	failOnreturn = false
end

while timesFailed <= maxRetries do
	begin
		s = TCPSocket.open("localhost", 2222)

		s.puts(mel)

		# Wait for Maya to finish running the command, especially important for
		# rendering commands that take a lot of time
		mayaReturn = s.gets()
		
		# Remove end of line characters
		mayaReturn.chomp!
		
		# If the render failed a return message will be in read in mayaReturn
		# but other commands return messages when they execute properly
		# so add the fail check as a parameter to the script
		if failOnreturn and not mayaReturn.empty?
			exit(-1)
		end
		
		exit(0)
	rescue Errno::ECONNREFUSED
		timesFailed += 1
		# Maya is not ready yet, wait a bit before retrying
		sleep(0.1)
	end
end

exit(-1)
