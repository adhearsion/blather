# Require the necessary files
require File.join(File.dirname(__FILE__), *%w[.. ext push_parser])
%w[
  rubygems
  eventmachine
  xml/libxml
  digest/md5
  logger

  blather/core_ext/active_support
  blather/core_ext/libxml

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

XML.indent_tree_output = false

module Blather
  @@logger = nil
  def self.logger
    unless @@logger
      @@logger = Logger.new($stdout)
      @@logger.level = Logger::INFO
    end
    @@logger
  end

  def self.logger=(logger)
    @@logger = logger
  end
end
