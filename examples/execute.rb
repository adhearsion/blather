#!/usr/bin/env ruby

require 'rubygems'
require 'blather/client'

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
