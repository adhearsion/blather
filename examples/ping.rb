require 'blather/client'

setup 'echo@jabber.local/ping', 'echo'

status :from => Blather::JID.new('echo@jabber.local/pong') do |s|
  say s.from, 'ping'
end

message :chat?, :body => 'pong' do |m|
  say m.from, 'ping'
end
