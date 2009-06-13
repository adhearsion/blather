require 'blather/client'

setup 'echo@jabber.local/pong', 'echo'
message :chat?, :body => 'ping' do |m|
  say m.from, 'pong'
end
