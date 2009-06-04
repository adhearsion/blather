module Blather
class Stanza
class PubSub

  class Subscribe < PubSub
    register :pubsub_subscribe, :subscribe, self.registered_ns

    def self.new(type = :set, host = nil, node = nil, jid = nil)
      new_node = super(type, host)
      new_node.node = node
      new_node.jid = jid
      new_node
    end

    def jid
      JID.new(subscribe[:jid])
    end

    def jid=(jid)
      subscribe[:jid] = jid
    end

    def node
      subscribe[:node]
    end

    def node=(node)
      subscribe[:node] = node
    end

    def subscribe
      unless subscribe = pubsub.find_first('ns:subscribe', :ns => self.class.registered_ns)
        self.pubsub << (subscribe = XMPPNode.new('subscribe', self.document))
        subscribe.namespace = self.pubsub.namespace
      end
      subscribe
    end
  end #Subscribe

end #PubSub
end #Stanza
end #Blather
