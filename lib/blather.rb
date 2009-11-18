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
  blather/stanza/pubsub/create
  blather/stanza/pubsub/event
  blather/stanza/pubsub/items
  blather/stanza/pubsub/publish
  blather/stanza/pubsub/retract
  blather/stanza/pubsub/subscribe
  blather/stanza/pubsub/subscription
  blather/stanza/pubsub/subscriptions
  blather/stanza/pubsub/unsubscribe

  blather/stanza/pubsub_owner
  blather/stanza/pubsub_owner/delete
  blather/stanza/pubsub_owner/purge

  blather/stream
  blather/stream/client
  blather/stream/component
  blather/stream/parser
  blather/stream/features
  blather/stream/features/resource
  blather/stream/features/sasl
  blather/stream/features/session
  blather/stream/features/tls
].each { |r| require r }

module Blather
  # @private
  @@logger = nil

  # Get or create an instance of Logger
  def self.logger
    unless @@logger
      self.logger = Logger.new($stdout)
      self.logger.level = Logger::INFO
    end
    @@logger
  end

  # Set the Logger
  def self.logger=(logger)
    @@logger = logger
  end
end
