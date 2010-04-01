#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), *%w[.. lib blather client])
require "blather/client/dsl/muc"

muc = Blather::DSL::MUC.new(client, "private-chat-102d075-d904-423-488-b394742923@conference.jabber.org/MyNick")

message :groupchat?, :body do |m|
  puts "New message: #{m.body}"
end

when_ready do
  muc.join
  muc.unlock do
    muc.say("What's that you said?")
  end
end