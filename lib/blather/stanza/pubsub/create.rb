module Blather
class Stanza
class PubSub

  class Create < PubSub
    register :pubsub_create, :create, self.registered_ns

    def self.new(type = :set, host = nil, node = nil)
      new_node = super(type, host)
      new_node.create_node
      new_node.configure_node
      new_node.node = node
      new_node
    end

    def node
      create_node[:node]
    end

    def node=(node)
      create_node[:node] = node
    end

    def create_node
      unless create_node = pubsub.find_first('ns:create', :ns => self.class.registered_ns)
        self.pubsub << (create_node = XMPPNode.new('create', self.document))
        create_node.namespace = self.pubsub.namespace
      end
      create_node
    end

    def configure_node
      unless configure_node = pubsub.find_first('ns:configure', :ns => self.class.registered_ns)
        self.pubsub << (configure_node = XMPPNode.new('configure', self.document))
        configure_node.namespace = self.pubsub.namespace
      end
      configure_node
    end
  end #Retract

end #PubSub
end #Stanza
end #Blather
