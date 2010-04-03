#!/usr/bin/env ruby

require File.join(File.dirname(__FILE__), *%w[.. lib blather client])
require "blather/client/dsl/muc"

message :groupchat?, :body do |m|
  puts "New message: #{m.body}"
end

muc_invite do |invite|
  puts "MUC INVITE"
  $muc = Blather::DSL::MUC.new(client, invite.from, "My Nick 2")
  $muc.join
  $muc.say("Yo yo - where is my yo yo?")
end