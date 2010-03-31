#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), *%w[.. lib blather client])
require "blather/client/dsl/muc"

message :groupchat? do |m|
  puts "New message: #{m.body}"
  muc.say "You sent: #{m.body}"
end

when_ready do
  muc = Blather::DSL::MUC.new(client, "private-chat-CB5BF3B4-C8A4-4C43-AAA0-96FBEC790569@groupchat.google.com/Test")
  muc.join
end