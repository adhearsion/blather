require 'rubygems'
require 'blather/client/dsl'
$stdout.sync = true

module Ping
  extend Blather::DSL
  def self.run; client.run; end

  setup 'ping@your.jabber.server', 'password'

  status :from => /pong@your\.jabber\.server/ do |s|
    puts "serve!"
    say s.from, 'ping'
  end

  message :chat?, :body => 'pong' do |m|
    puts "ping!"
    say m.from, 'ping'
  end
end

module Pong
  extend Blather::DSL
  def self.run; client.run; end

  setup 'pong@your.jabber.server', 'password'
  message :chat?, :body => 'ping' do |m|
    puts "pong!"
    say m.from, 'pong'
  end
end

trap(:INT) { EM.stop }
trap(:TERM) { EM.stop }
EM.run do
  Ping.run
  Pong.run
end
