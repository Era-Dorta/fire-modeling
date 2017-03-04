#!/usr/bin/env ruby

require 'socket'
require 'timeout'

# maxRetries * 0.1 = number of seconds waiting for Maya to load
maxRetries = 50
timesFailed = 0
maxTimeCommand = 30*60 # If a render takes more than 30 minutes assume it's stuck

if ARGV.size < 2 or ARGV.size > 3
	puts "Usage : sendMaya <port> <maya command>"
	puts "\tOptional second boolean argument fail on return value, default is false"
	exit(0)
end

port = ARGV[0].to_i
mel = ARGV[1]

if ARGV.size == 3
	if ARGV[2] == "1" or ARGV[2] == "true"
		failOnreturn = true
	else
		failOnreturn = false
	end
else
	failOnreturn = false
end

Timeout::timeout(maxTimeCommand) {
	while timesFailed <= maxRetries do
		begin
			s = TCPSocket.open("localhost", port)

			s.puts(mel)

			# Wait for Maya to finish running the command, especially important for
			# rendering commands that take a lot of time
			mayaReturn = s.gets()
		
			# Output the response from Maya, commonly it will be "\n"
			puts(mayaReturn)
		
			# Close the socket
			s.close
		
			# If the render failed a return message will be in read in mayaReturn
			# but other commands return messages when they execute properly
			# so add the fail check as a parameter to the script
			if failOnreturn and mayaReturn != "\n"
				exit(-1)
			end
		
			exit(0)
		rescue Errno::ECONNREFUSED
			timesFailed += 1
			# Maya is not ready yet, wait a bit before retrying
			sleep(0.1)
		end
	end
}

exit(-1)
