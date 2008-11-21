$:.unshift File.dirname(__FILE__)

%w[
  rubygems
  xml/libxml
  eventmachine
  digest/md5
  logger

  blather/callback

  blather/core/errors
  blather/core/jid
  blather/core/roster
  blather/core/roster_item
  blather/core/sugar
  blather/core/xmpp_node

  blather/core/stanza
  blather/core/stanza/iq
  blather/core/stanza/iq/query
  blather/core/stanza/iq/roster
  blather/core/stanza/message
  blather/core/stanza/presence
  blather/core/stanza/presence/status
  blather/core/stanza/presence/subscription

  blather/core/stream
  blather/core/stream/parser
  blather/core/stream/resource
  blather/core/stream/sasl
  blather/core/stream/session
  blather/core/stream/tls
].each { |r| require r }

XML::Parser.indent_tree_output = false

module Blather
  LOG = Logger.new STDOUT

  def run(jid, password, client, host = nil, port = 5222)
    EM.run { Stream.start client, JID.new(jid), password, host, port }
  end
  module_function :run

  MAJOR = 0
  MINOR = 1
  VERSION = [MAJOR, MINOR]*'.'

  def version
    VERSION
  end
  module_function :version
end
