module Blather
class Stanza

  class PubSub < Iq
    register :pubsub, :pubsub, 'http://jabber.org/protocol/pubsub'

    %w[affiliations subscriptions].each do |type|
      class_eval <<-METHOD
        def self.#{type}(host)
          node = self.new :get
          node.to = host
          node.pubsub << XMPPNode.new('#{type}')
          node
        end
      METHOD
    end

    def self.items(host, path, list = [], max = nil)
      node = self.new :get
      node.to = host

      items = XMPPNode.new 'items'
      items.attributes[:node] = path
      items.attributes[:max_items] = max

      (list || []).each do |id|
        item = XMPPNode.new 'item'
        item.attributes[:id] = id
        items << item
      end

      node.pubsub << items
      node
    end

    ##
    # Ensure the namespace is set to the query node
    def initialize(type = nil)
      super
      pubsub.namespace = self.class.ns
    end

    def pubsub
      p = find_first('pubsub')
      p = find_first('//pubsub_ns:pubsub', :pubsub_ns => self.class.ns) if !p && self.class.ns
      (self << (p = XMPPNode.new('pubsub'))) unless p
      p
    end

    def affiliations
      items = pubsub.find('//pubsub_ns:affiliation', :pubsub_ns => self.class.ns)
      items.inject({}) do |hash, item|
        hash[item.attributes[:affiliation].to_sym] ||= []
        hash[item.attributes[:affiliation].to_sym] << item.attributes[:node]
        hash
      end
    end

    def subscriptions
      items = pubsub.find('//pubsub_ns:subscription', :pubsub_ns => self.class.ns)
      items.inject({}) do |hash, item|
        hash[item.attributes[:subscription].to_sym] ||= []
        hash[item.attributes[:subscription].to_sym] << item.attributes[:node]
        hash
      end
    end
  end

end #Stanza
end #Blather
