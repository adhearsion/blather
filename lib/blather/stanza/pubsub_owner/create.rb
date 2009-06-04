module Blather
class Stanza
class PubSubOwner

  class Create < PubSubOwner
    
    register :pubsub_create, :create, self.registered_ns

    def self.new(type = :set, host = nil, node = nil)
      new_node = super(type, host)
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
  end #Retract

end #PubSub
end #Stanza
end #Blather
