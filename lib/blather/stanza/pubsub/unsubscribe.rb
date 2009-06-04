module Blather
class Stanza
class PubSub

  class Unsubscribe < PubSub
    register :pubsub_unsubscribe, :unsubscribe, self.registered_ns

    def self.new(type = :set, host = nil, node = nil, jid = nil)
      new_node = super(type, host)
      new_node.node = node
      new_node.jid = jid
      new_node
    end

    def jid
      JID.new(unsubscribe[:jid])
    end

    def jid=(jid)
      unsubscribe[:jid] = jid
    end

    def node
      unsubscribe[:node]
    end

    def node=(node)
      unsubscribe[:node] = node
    end

    def unsubscribe
      unless unsubscribe = pubsub.find_first('ns:unsubscribe', :ns => self.class.registered_ns)
        self.pubsub << (unsubscribe = XMPPNode.new('unsubscribe', self.document))
        unsubscribe.namespace = self.pubsub.namespace
      end
      unsubscribe
    end
  end #Unsubscribe

end #PubSub
end #Stanza
end #Blather
