# Require the necessary files
%w[
  rubygems
  eventmachine
  nokogiri
  ipaddr
  digest/md5
  digest/sha1
  logger
  openssl
  girl_friday

  active_support/core_ext/class/attribute
  active_support/core_ext/object/blank

  blather/core_ext/eventmachine
  blather/core_ext/ipaddr

  blather/cert_store
  blather/errors
  blather/errors/sasl_error
  blather/errors/stanza_error
  blather/errors/stream_error
  blather/file_transfer
  blather/file_transfer/ibb
  blather/file_transfer/s5b
  blather/jid
  blather/roster
  blather/roster_item
  blather/xmpp_node

  blather/stanza
  blather/stanza/iq
  blather/stanza/iq/command
  blather/stanza/iq/ibb
  blather/stanza/iq/ping
  blather/stanza/iq/query
  blather/stanza/iq/roster
  blather/stanza/iq/s5b
  blather/stanza/iq/si
  blather/stanza/iq/vcard
  blather/stanza/disco
  blather/stanza/disco/disco_info
  blather/stanza/disco/disco_items
  blather/stanza/disco/capabilities
  blather/stanza/message
  blather/stanza/message/muc_user
  blather/stanza/presence
  blather/stanza/presence/c
  blather/stanza/presence/status
  blather/stanza/presence/subscription
  blather/stanza/presence/muc
  blather/stanza/presence/muc_user

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

  blather/stanza/x

  blather/stream
  blather/stream/client
  blather/stream/component
  blather/stream/parser
  blather/stream/features
  blather/stream/features/resource
  blather/stream/features/sasl
  blather/stream/features/session
  blather/stream/features/tls
  blather/stream/features/register
].each { |r| require r }

module Blather
  @@logger = nil

  class << self

    # Default logger level. Any internal call to log() will forward the log message to
    # the default log level
    attr_accessor :default_log_level

    def logger
      @@logger ||= Logger.new($stdout).tap {|logger| logger.level = Logger::INFO }
    end

    def logger=(logger)
      @@logger = logger
    end

    def default_log_level
      @default_log_level ||= :debug # by default is debug (as it used to be)
    end

    def log(message)
      logger.send self.default_log_level, message
    end

  end

end
