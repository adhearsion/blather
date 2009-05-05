module Blather
class Stanza
class PubSub

  class Items < PubSub
    register :pubsub_items, :pubsub_items, self.ns

    include Enumerable

    def self.request(host, path, list = [], max = nil)
      node = self.new :get, host

      node.items.attributes[:node] = path
      node.items.attributes[:max_items] = max

      (list || []).each do |id|
        item = XMPPNode.new 'item'
        item.attributes[:id] = id
        node.items << item
      end

      node
    end

    def initialize(type = nil, host = nil)
      super
      items
    end

    ##
    # Kill the items node before running inherit
    def inherit(node)
      items.remove!
      super
    end

    def [](id)
      items[id]
    end

    def each(&block)
      items.each &block
    end

    def size
      items.size
    end

    def items
      items = pubsub.find_first('//items', self.class.ns)
      items = pubsub.find_first('//pubsub_ns:items', :pubsub_ns => self.class.ns) unless items
      (self.pubsub << (items = XMPPNode.new('items'))) unless items
      items
    end
  end

end #PubSub
end #Stanza
end #Blather
