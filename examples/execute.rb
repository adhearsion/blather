#!/usr/bin/env ruby

require 'blather/client'
require 'blather/client/pubsub'

setup 'echo@jabber.local', 'echo'

Blather::LOG.level = Logger::DEBUG

message :chat?, :body => 'exit' do |m|
  say m.from, 'Exiting ...'
  shutdown
end

message :chat?, :body do |m|
  begin
    say m.from, eval(m.body)
  rescue => e
    say m.from, e.inspect
  end
end
