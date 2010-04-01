#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), *%w[.. lib blather client])
require "blather/client/dsl/muc"

muc = Blather::DSL::MUC.new(client, "private-chat-882d0b5b-d904-4b23-9488-b894742deee7@conference.jabber.org/Test Group", "xxx")

message :groupchat? do |m|
  puts "New message: #{m.body}"
  muc.say "You sent: #{m.body}"
end

when_ready do
  muc.join
end