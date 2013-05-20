module Blather
class Stanza
class PubSubOwner

  # # PubSubOwner Delete Stanza
  #
  # [XEP-0060 Section 8.4 Delete a Node](http://xmpp.org/extensions/xep-0060.html#owner-delete)
  #
  # @handler :pubsub_delete
  class Delete < PubSubOwner
    register :pubsub_delete, :delete, self.registered_ns

    # Create a new delete stanza
    #
    # @param [Blather::Stanza::Iq::VALID_TYPES] type the IQ stanza type
    # @param [String] host the host to send the request to
    # @param [String] node the name of the node to delete
    def self.new(type = :set, host = nil, node = nil)
      new_node = super(type, host)
      new_node.node = node
      new_node
    end

    # Get the name of the node to delete
    #
    # @return [String]
    def node
      delete_node[:node]
    end

    # Set the name of the node to delete
    #
    # @param [String] node
    def node=(node)
      delete_node[:node] = node
    end

    # Get or create the actual delete node on the stanza
    #
    # @return [Blather::XMPPNode]
    def delete_node
      unless delete_node = pubsub.at_xpath('ns:delete', :ns => self.class.registered_ns)
        self.pubsub << (delete_node = XMPPNode.new('delete', self.document))
        delete_node.namespace = self.pubsub.namespace
      end
      delete_node
    end
  end  # Retract

end  # PubSub
end  # Stanza
end  # Blather
