module Blather
class Stanza
class PubSub

  # # PubSub Subscribe Stanza
  #
  # [XEP-0060 Section 6.1 - Subscribe to a Node](http://xmpp.org/extensions/xep-0060.html#subscriber-subscribe)
  #
  # @handler :pubsub_subscribe
  class Subscribe < PubSub
    register :pubsub_subscribe, :subscribe, self.registered_ns

    # Create a new subscription node
    #
    # @param [Blather::Stanza::Iq::VALID_TYPES] type the IQ stanza type
    # @param [String] host the host name to send the request to
    # @param [String] node the node to subscribe to
    # @param [Blather::JID, #to_s] jid see {#jid=}
    def self.new(type = :set, host = nil, node = nil, jid = nil)
      new_node = super(type, host)
      new_node.node = node
      new_node.jid = jid
      new_node
    end

    # Get the JID of the entity to subscribe
    #
    # @return [Blather::JID]
    def jid
      JID.new(subscribe[:jid])
    end

    # Set the JID of the entity to subscribe
    #
    # @param [Blather::JID, #to_s] jid
    def jid=(jid)
      subscribe[:jid] = jid
    end

    # Get the name of the node to subscribe to
    #
    # @return [String]
    def node
      subscribe[:node]
    end

    # Set the name of the node to subscribe to
    #
    # @param [String] node
    def node=(node)
      subscribe[:node] = node
    end

    # Get or create the actual subscribe node on the stanza
    #
    # @return [Blather::XMPPNode]
    def subscribe
      unless subscribe = pubsub.at_xpath('ns:subscribe', :ns => self.class.registered_ns)
        self.pubsub << (subscribe = XMPPNode.new('subscribe', self.document))
        subscribe.namespace = self.pubsub.namespace
      end
      subscribe
    end
  end  # Subscribe

end  # PubSub
end  # Stanza
end  # Blather
