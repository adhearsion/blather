module Blather
class Stanza
class PubSub

  class Event < Message
    register :pubsub_event, :event, 'http://jabber.org/protocol/pubsub#event'

    ##
    # Ensure the event_node is created
    def self.new(type = nil)
      node = super
      node.event_node
      node
    end

    ##
    # Kill the event_node node before running inherit
    def inherit(node)
      event_node.remove
      super
    end

    def node
      items_node[:node]
    end

    def retractions
      items_node.find('ns:retract', :ns => self.class.registered_ns).map { |i| i[:id] }
    end

    def retractions?
      !retractions.empty?
    end

    def items
      items_node.find('ns:item', :ns => self.class.registered_ns).map { |i| PubSubItem.new.inherit i }
    end

    def items?
      !items.empty?
    end

    def event_node
      node = find_first('ns:event', :ns => self.class.registered_ns)
      node = find_first('event', self.class.registered_ns) unless node
      unless node
        (self << (node = XMPPNode.new('event', self.document)))
        node.namespace = self.class.registered_ns
      end
      node
    end

    def items_node
      node = find_first('event/ns:items', :ns => self.class.registered_ns)
      unless node
        (self.event_node << (node = XMPPNode.new('items', self.document)))
        node.namespace = event_node.namespace
      end
      node
    end

    def subscription_ids
      find('//ns:header[@name="SubID"]', :ns => 'http://jabber.org/protocol/shim').map { |n| n.content }
    end
  end

end #PubSub
end #Stanza
end #Blather
