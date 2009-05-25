# Require the necessary files
%w[
  rubygems
  eventmachine
  nokogiri
  digest/md5
  logger

  blather/core_ext/active_support
  blather/core_ext/nokogiri

  blather/errors
  blather/errors/sasl_error
  blather/errors/stanza_error
  blather/errors/stream_error
  blather/jid
  blather/roster
  blather/roster_item
  blather/xmpp_node

  blather/stanza
  blather/stanza/iq
  blather/stanza/iq/query
  blather/stanza/iq/roster
  blather/stanza/disco
  blather/stanza/disco/disco_info
  blather/stanza/disco/disco_items
  blather/stanza/message
  blather/stanza/presence
  blather/stanza/presence/status
  blather/stanza/presence/subscription
  blather/stanza/pubsub
  blather/stanza/pubsub/affiliations
  blather/stanza/pubsub/subscriptions
  blather/stanza/pubsub/items
  blather/stanza/pubsub/event

  blather/stream
  blather/stream/client
  blather/stream/component
  blather/stream/stream_handler
  blather/stream/parser
  blather/stream/resource
  blather/stream/sasl
  blather/stream/session
  blather/stream/tls
].each { |r| require r }

module Blather
  LOG = Logger.new($stdout) unless const_defined?(:LOG)
  LOG.level = Logger::INFO
end
