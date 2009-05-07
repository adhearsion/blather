module Blather
class Stanza
class PubSub

  class Items < PubSub
    register :pubsub_items, :pubsub_items, self.ns

    include Enumerable

    def self.request(host, path, list = [], max = nil)
      node = self.new :get, host

      node.node = path
      node.max_items = max

      (list || []).each { |id| node.items_node << PubSubItem.new(id) }

      node
    end

    def initialize(type = nil, host = nil)
      super
      items
    end

    ##
    # Kill the items node before running inherit
    def inherit(node)
      items_node.remove!
      super
    end

    def node
      items_node.attributes[:node]
    end

    def node=(node)
      items_node.attributes[:node] = node
    end

    def max_items
      items_node.attributes[:max_items].to_i if items_node.attributes[:max_items]
    end

    def max_items=(max_items)
      items_node.attributes[:max_items] = max_items
    end

    def each(&block)
      items.each &block
    end

    def items
      items_node.map { |i| PubSubItem.new.inherit i }
    end

    def items_node
      node = pubsub.find_first('//items', self.class.ns)
      node = pubsub.find_first('//pubsub_ns:items', :pubsub_ns => self.class.ns) unless node
      (self.pubsub << (node = XMPPNode.new('items'))) unless node
      node
    end

    class PubSubItem < XMPPNode
      def initialize(id = nil, payload = nil)
        super 'item'
        self.id = id
        self.payload = payload
      end

      attribute_accessor :id, :to_sym => false

      def payload=(payload = nil)
        self.content = (payload ? payload : '')
      end

      def payload
        content.empty? ? nil : content
      end
    end
  end

end #PubSub
end #Stanza
end #Blather
