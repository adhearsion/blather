$:.unshift File.dirname(__FILE__)

%w[
  rubygems
  xml/libxml
  eventmachine
  digest/md5
  logger

  blather/errors
  blather/jid
  blather/roster
  blather/roster_item
  blather/sugar
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
  blather/stream/parser
  blather/stream/resource
  blather/stream/sasl
  blather/stream/session
  blather/stream/tls
].each { |r| require r }

XML::Parser.indent_tree_output = false

module Blather
  VERSION = '0.1'
  LOG = Logger.new STDOUT

  def run(jid, password, client, host = nil, port = 5222)
    EM.run { Stream.start client, JID.new(jid), password, host, port }
  end
  module_function :run
end
