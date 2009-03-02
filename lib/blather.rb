$:.unshift File.dirname(__FILE__)
$:.unshift File.join(File.dirname(__FILE__), *%w[vendor libxml lib])

# Require the necessary files
%w[
  rubygems
  vendor/libxml/lib/xml
  eventmachine
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
  blather/stanza/message
  blather/stanza/presence
  blather/stanza/presence/status
  blather/stanza/presence/subscription

  blather/stream
  blather/stream/stream_handler
  blather/stream/parser
  blather/stream/resource
  blather/stream/sasl
  blather/stream/session
  blather/stream/tls
].each { |r| require r }

XML.indent_tree_output = false

module Blather
  LOG = Logger.new(STDOUT) unless const_defined?(:LOG)
  LOG.level = Logger::INFO
end