module Blather
class Stanza
class PubSub

  # # PubSub Unsubscribe Stanza
  #
  # [XEP-0060 Section 6.2 - Unsubscribe from a Node](http://xmpp.org/extensions/xep-0060.html#subscriber-unsubscribe)
  #
  # @handler :pubsub_unsubscribe
  class Unsubscribe < PubSub
    register :pubsub_unsubscribe, :unsubscribe, self.registered_ns

    # Create a new unsubscribe node
    #
    # @param [Blather::Stanza::Iq::VALID_TYPES] type the IQ stanza type
    # @param [String] host the host to send the request to
    # @param [String] node the node to unsubscribe from
    # @param [Blather::JID, #to_s] jid the JID of the unsubscription
    def self.new(type = :set, host = nil, node = nil, jid = nil)
      new_node = super(type, host)
      new_node.node = node
      new_node.jid = jid
      new_node
    end

    # Get the JID of the unsubscription
    #
    # @return [Blather::JID]
    def jid
      JID.new(unsubscribe[:jid])
    end

    # Set the JID of the unsubscription
    #
    # @param [Blather::JID, #to_s] jid
    def jid=(jid)
      unsubscribe[:jid] = jid
    end

    # Get the name of the node to unsubscribe from
    #
    # @return [String]
    def node
      unsubscribe[:node]
    end

    # Set the name of the node to unsubscribe from
    #
    # @param [String] node
    def node=(node)
      unsubscribe[:node] = node
    end

    # Get or create the actual unsubscribe node
    #
    # @return [Blather::XMPPNode]
    def unsubscribe
      unless unsubscribe = pubsub.find_first('ns:unsubscribe', :ns => self.class.registered_ns)
        self.pubsub << (unsubscribe = XMPPNode.new('unsubscribe', self.document))
        unsubscribe.namespace = self.pubsub.namespace
      end
      unsubscribe
    end
  end  # Unsubscribe

end  # PubSub
end  # Stanza
end  # Blather
