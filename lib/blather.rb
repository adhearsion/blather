$:.unshift File.dirname(__FILE__)

%w[
  rubygems
  xml/libxml
  eventmachine
  digest/md5

  blather/callback

  blather/core/errors
  blather/core/jid
  blather/core/roster
  blather/core/roster_item
  blather/core/sugar
  blather/core/xmpp_node

  blather/core/stanza
  blather/core/stanzas/error
  blather/core/stanzas/iq
  blather/core/stanzas/iqs/query
  blather/core/stanzas/iqs/queries/roster
  blather/core/stanzas/message
  blather/core/stanzas/presence
  blather/core/stanzas/presences/status
  blather/core/stanzas/presences/subscription

  blather/core/stream
  blather/core/streams/parser
  blather/core/streams/resource
  blather/core/streams/sasl
  blather/core/streams/session
  blather/core/streams/tls
].each { |r| require r }

XML::Parser.indent_tree_output = false

module Blather
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
