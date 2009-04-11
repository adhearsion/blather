#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), %w[.. lib])
require 'blather/client'
Blather::LOG.level = Logger::DEBUG
if ARGV.length < 2
  puts "Run with ./echo.rb user@server/resource password [host] [port]"
  exit 1
end

setup *ARGV

when_ready { puts "Connected ! send messages to #{jid.stripped}." }

message :chat?, :body => 'exit' do |m|
  say m.from, 'Exiting ...'
  shutdown || true
end

message :chat?, :body do |m|
  say m.from, "You sent: #{m.body}"
end
