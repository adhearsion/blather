module Blather
class Stanza
class PubSubOwner

  # # PubSubOwner Purge Stanza
  #
  # [XEP-0060 Section 8.5 - Purge All Node Items](http://xmpp.org/extensions/xep-0060.html#owner-purge)
  #
  # @handler :pubsub_purge
  class Purge < PubSubOwner
    register :pubsub_purge, :purge, self.registered_ns

    # Create a new purge stanza
    #
    # @param [Blather::Stanza::Iq::VALID_TYPES] type the IQ stanza type
    # @param [String] host the host to send the request to
    # @param [String] node the name of the node to purge
    def self.new(type = :set, host = nil, node = nil)
      new_node = super(type, host)
      new_node.node = node
      new_node
    end

    # Get the name of the node to delete
    #
    # @return [String]
    def node
      purge_node[:node]
    end

    # Set the name of the node to delete
    #
    # @param [String] node
    def node=(node)
      purge_node[:node] = node
    end

    # Get or create the actual purge node on the stanza
    #
    # @return [Blather::XMPPNode]
    def purge_node
      unless purge_node = pubsub.at_xpath('ns:purge', :ns => self.class.registered_ns)
        self.pubsub << (purge_node = XMPPNode.new('purge', self.document))
        purge_node.namespace = self.pubsub.namespace
      end
      purge_node
    end
  end  # Retract

end  # PubSub
end  # Stanza
end  # Blather
