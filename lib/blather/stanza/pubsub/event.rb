module Blather
class Stanza
class PubSub

  class Event < Message
    register :pubsub_event, :event, 'http://jabber.org/protocol/pubsub#event'

    def node
      items_node.attributes[:node]
    end

    def items
      items_node.map { |i| PubSubItem.new.inherit i }
    end

    def items_node
      node = find_first('//items', self.class.ns)
      node = find_first('//pubsub_ns:items', :pubsub_ns => self.class.ns) unless node
      (self.pubsub << (node = XMPPNode.new('items'))) unless node
      node
    end

    def subscription_ids
      find('//hns:header[@name="SubID"]', :hns => 'http://jabber.org/protocol/shim').map { |n| n.content }
    end
  end

end #PubSub
end #Stanza
end #Blather
