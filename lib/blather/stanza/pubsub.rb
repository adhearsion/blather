module Blather
class Stanza

  class PubSub < Iq
    register :pubsub, :pubsub, 'http://jabber.org/protocol/pubsub'

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
      pubsub.namespace = self.class.ns unless pubsub.namespace
    end

    ##
    # Kill the pubsub node before running inherit
    def inherit(node)
      pubsub.remove!
      super
    end

    def pubsub
      unless p = find_first('//pubsub', Stanza::PubSub::Affiliations.ns)
        p = XMPPNode.new('pubsub')
        p.namespace = self.class.ns
        self << p
      end
      p
    end
  end

end #Stanza
end #Blather
