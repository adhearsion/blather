module Blather
class Stanza
class PubSub

  class Items < PubSub
    register :pubsub_items, :items, self.registered_ns

    include Enumerable
    alias_method :find, :xpath

    def self.request(host, path, list = [], max = nil)
      node = self.new :get, host

      node.node = path
      node.max_items = max

      (list || []).each { |id| node.items_node << PubSubItem.new(id, nil, node.document) }

      node
    end

    def self.new(type = nil, host = nil)
      new_node = super
      new_node.items
      new_node
    end

    def node
      items_node[:node]
    end

    def node=(node)
      items_node[:node] = node
    end

    def max_items
      items_node[:max_items].to_i if items_node[:max_items]
    end

    def max_items=(max_items)
      items_node[:max_items] = max_items
    end

    def each(&block)
      items.each &block
    end

    def items
      items_node.find('ns:item', :ns => self.class.registered_ns).map { |i| PubSubItem.new(nil,nil,self.document).inherit i }
    end

    def items_node
      unless node = self.pubsub.find_first('ns:items', :ns => self.class.registered_ns)
        (self.pubsub << (node = XMPPNode.new('items', self.document)))
        node.namespace = self.pubsub.namespace
      end
      node
    end
  end

end #PubSub
end #Stanza
end #Blather
