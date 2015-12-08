#!/usr/bin/env ruby

require 'socket'

begin

mel = STDIN.read

s = TCPSocket.open("localhost", 2222)

s.puts(mel)

end
