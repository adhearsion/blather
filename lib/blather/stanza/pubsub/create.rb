module Blather
class Stanza
class PubSub

  # # PubSub Create Stanza
  #
  # [XEP-0060 Section 8.1 - Create a Node](http://xmpp.org/extensions/xep-0060.html#owner-create)
  #
  # @handler :pubsub_create
  class Create < PubSub
    register :pubsub_create, :create, self.registered_ns

    # Create a new Create Stanza
    #
    # @param [<Blather::Stanza::Iq::VALID_TYPES>] type the node type
    # @param [String, nil] host the host to send the request to
    # @param [String, nil] node the name of the node to create
    def self.new(type = :set, host = nil, node = nil)
      new_node = super(type, host)
      new_node.create_node
      new_node.configure_node
      new_node.node = node
      new_node
    end

    # Get the name of the node to create
    #
    # @return [String, nil]
    def node
      create_node[:node]
    end

    # Set the name of the node to create
    #
    # @param [String, nil] node
    def node=(node)
      create_node[:node] = node
    end

    # Get or create the actual create node on the stanza
    #
    # @return [Blather::XMPPNode]
    def create_node
      unless create_node = pubsub.find_first('ns:create', :ns => self.class.registered_ns)
        self.pubsub << (create_node = XMPPNode.new('create', self.document))
        create_node.namespace = self.pubsub.namespace
      end
      create_node
    end

    # Get or create the actual configure node on the stanza
    #
    # @return [Blather::XMPPNode]
    def configure_node
      unless configure_node = pubsub.find_first('ns:configure', :ns => self.class.registered_ns)
        self.pubsub << (configure_node = XMPPNode.new('configure', self.document))
        configure_node.namespace = self.pubsub.namespace
      end
      configure_node
    end
  end  # Create

end  # PubSub
end  # Stanza
end  # Blather
