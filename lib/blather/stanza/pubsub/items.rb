module Blather
class Stanza
class PubSub

  # # PubSub Items Stanza
  #
  # [XEP-0060 Section 6.5 - Retrieve Items from a Node](http://xmpp.org/extensions/xep-0060.html#subscriber-retrieve)
  #
  # @handler :pubsub_items
  class Items < PubSub
    register :pubsub_items, :items, self.registered_ns

    include Enumerable
    alias_method :find, :xpath

    # Create a new Items request
    #
    # @param [String] host the pubsub host to send the request to
    # @param [String] path the path of the node
    # @param [Array<String>] list an array of IDs to request
    # @param [#to_s] max the maximum number of items to return
    #
    # @return [Blather::Stanza::PubSub::Items]
    def self.request(host, path, list = [], max = nil)
      node = self.new :get, host

      node.node = path
      node.max_items = max

      (list || []).each do |id|
        node.items_node << PubSubItem.new(id, nil, node.document)
      end

      node
    end

    # Overrides the parent to ensure an items node is created
    # @private
    def self.new(type = nil, host = nil)
      new_node = super
      new_node.items
      new_node
    end

    # Get the node name
    #
    # @return [String]
    def node
      items_node[:node]
    end

    # Set the node name
    #
    # @param [String, nil] node
    def node=(node)
      items_node[:node] = node
    end

    # Get the max number of items requested
    #
    # @return [Fixnum, nil]
    def max_items
      items_node[:max_items].to_i if items_node[:max_items]
    end

    # Set the max number of items requested
    #
    # @param [Fixnum, nil] max_items
    def max_items=(max_items)
      items_node[:max_items] = max_items
    end

    # Iterate over the list of items
    #
    # @yieldparam [Blather::Stanza::PubSub::PubSubItem] item
    def each(&block)
      items.each &block
    end

    # Get the list of items on this stanza
    #
    # @return [Array<Blather::Stanza::PubSub::PubSubItem>]
    def items
      items_node.find('ns:item', :ns => self.class.registered_ns).map do |i|
        PubSubItem.new(nil,nil,self.document).inherit i
      end
    end

    # Get or create the actual items node
    #
    # @return [Blather::XMPPNode]
    def items_node
      unless node = self.pubsub.find_first('ns:items', :ns => self.class.registered_ns)
        (self.pubsub << (node = XMPPNode.new('items', self.document)))
        node.namespace = self.pubsub.namespace
      end
      node
    end
  end  # Items

end  # PubSub
end  # Stanza
end  # Blather
