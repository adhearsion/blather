module Blather
class Stanza
class Iq

  # # Ping Stanza
  #
  # [XEP-0199: XMPP Ping](http://xmpp.org/extensions/xep-0199.html)
  #
  # This is a base class for any Ping based Iq stanzas.
  #
  # @handler :ping
  class Ping < Iq
    # @private
    register :ping, :ping, 'urn:xmpp:ping'

    # Overrides the parent method to ensure a ping node is created
    #
    # @see Blather::Stanza::Iq.new
    def self.new(type = :get, to = nil, id = nil)
      node = super
      node.ping
      node
    end

    # Overrides the parent method to ensure the current ping node is destroyed
    #
    # @see Blather::Stanza::Iq#inherit
    def inherit(node)
      ping.remove
      super
    end

    # Ping node accessor
    # If a ping node exists it will be returned.
    # Otherwise a new node will be created and returned
    #
    # @return [Balather::XMPPNode]
    def ping
      p = at_xpath 'ns:ping', :ns => self.class.registered_ns

      unless p
        (self << (p = XMPPNode.new('ping', self.document)))
        p.namespace = self.class.registered_ns
      end
      p
    end
  end
end
end
end
