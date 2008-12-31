#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), %w[.. lib])
require 'blather/client'

if ARGV.length != 2
  puts "Run with ./echo.rb user@server/resource password"
  exit 1
end

setup ARGV[0], ARGV[1]

handle :ready do
  puts "Connected ! send messages to #{jid.stripped}."
end

# Echo back what was said
handle :message do |m|
  if m.chat? && m.body
    if m.body == 'exit'
      say m.from, 'Exiting ...'
      EM.stop
    else
      m.body = "You sent: #{m.body}"
      write m.reply!
    end
  end
end
