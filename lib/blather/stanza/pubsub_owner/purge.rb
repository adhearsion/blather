module Blather
class Stanza
class PubSubOwner

  class Purge < PubSubOwner
    
    register :pubsub_purge, :purge, self.registered_ns

    def self.new(type = :set, host = nil, node = nil)
      new_node = super(type, host)
      new_node.node = node
      new_node
    end

    def node
      purge_node[:node]
    end

    def node=(node)
      purge_node[:node] = node
    end

    def purge_node
      unless purge_node = pubsub.find_first('ns:purge', :ns => self.class.registered_ns)
        self.pubsub << (purge_node = XMPPNode.new('purge', self.document))
        purge_node.namespace = self.pubsub.namespace
      end
      purge_node
    end
  end #Retract

end #PubSub
end #Stanza
end #Blather
