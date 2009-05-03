setup 'ping-pong@jabber.local', 'ping-pong'

pubsub.host = 'pubsub.jabber.local'

pubsub_event :node => 'ping' do |node|
  pubsub.publish 'pong', node.payload
end

pubsub_event :node => 'pong' do |node|
  x = node.payload.to_i
  if x > 0
    pubsub.publish 'ping', (x - 1)
  else
    shutdown
  end
end

when_ready { pubsub.publish 'ping', 3 }
