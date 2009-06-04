module Blather
class Stanza
class PubSub

  class Publish < PubSub
    register :pubsub_publish, :publish, self.registered_ns

    include Enumerable
    alias_method :find, :xpath

    def self.new(host = nil, node = nil, type = :set, payload = nil)
      new_node = super(type, host)
      new_node.node = node
      new_node.payload = payload if payload
      new_node
    end

    def payload=(payload)
      payload = case payload
      when Hash   then  payload.to_a
      when Array  then  payload.map { |v| [nil, v] }
      else              [[nil, payload.to_s]]
      end
      payload.each { |id,value| self.publish << PubSubItem.new(id, value, self.document) }
    end

    def node
      publish[:node]
    end

    def node=(node)
      publish[:node] = node
    end

    def publish
      unless publish = pubsub.find_first('ns:publish', :ns => self.class.registered_ns)
        self.pubsub << (publish = XMPPNode.new('publish', self.document))
        publish.namespace = self.pubsub.namespace
      end
      publish
    end

    def items
      publish.find('ns:item', :ns => self.class.registered_ns).map { |i| PubSubItem.new(nil,nil,self.document).inherit i }
    end

    def each(&block)
      items.each &block
    end

    def size
      items.size
    end
  end #Publish

end #PubSub
end #Stanza
end #Blather
