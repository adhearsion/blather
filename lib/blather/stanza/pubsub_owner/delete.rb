module Blather
class Stanza
class PubSubOwner

  class Delete < PubSubOwner
    
    register :pubsub_delete, :delete, self.registered_ns

    def self.new(type = :set, host = nil, node = nil)
      new_node = super(type, host)
      new_node.node = node
      new_node
    end

    def node
      delete_node[:node]
    end

    def node=(node)
      delete_node[:node] = node
    end

    def delete_node
      unless delete_node = pubsub.find_first('ns:delete', :ns => self.class.registered_ns)
        self.pubsub << (delete_node = XMPPNode.new('delete', self.document))
        delete_node.namespace = self.pubsub.namespace
      end
      delete_node
    end
  end #Retract

end #PubSub
end #Stanza
end #Blather
