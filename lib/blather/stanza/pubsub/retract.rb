module Blather
class Stanza
class PubSub

  class Retract < PubSub
    register :pubsub_retract, :retract, self.registered_ns

    include Enumerable
    alias_method :find, :xpath

    def self.new(host = nil, node = nil, type = :set, retractions = [])
      new_node = super(type, host)
      new_node.node = node
      new_node.retractions = retractions
      new_node
    end

    def node
      retract[:node]
    end

    def node=(node)
      retract[:node] = node
    end

    def retract
      unless retract = pubsub.find_first('ns:retract', :ns => self.class.registered_ns)
        self.pubsub << (retract = XMPPNode.new('retract', self.document))
        retract.namespace = self.pubsub.namespace
      end
      retract
    end

    def retractions=(retractions = [])
      [retractions].flatten.each { |id| self.retract << PubSubItem.new(id, nil, self.document) }
    end

    def retractions
      retract.find('ns:item', :ns => self.class.registered_ns).map { |i| i[:id] }
    end

    def each(&block)
      retractions.each &block
    end

    def size
      retractions.size
    end
  end #Retract

end #PubSub
end #Stanza
end #Blather
