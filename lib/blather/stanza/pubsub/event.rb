module Blather
class Stanza
class PubSub

  # # PubSub Event Stanza
  #
  # [XEP-0060](http://xmpp.org/extensions/xep-0060.html)
  #
  # The PubSub Event stanza is used in many places. Please see the XEP for more
  # information.
  #
  # @handler :pubsub_event
  class Event < Message
    # @private
    SHIM_NS = 'http://jabber.org/protocol/shim'.freeze

    register :pubsub_event, :event, 'http://jabber.org/protocol/pubsub#event'

    # Ensures the event_node is created
    # @private
    def self.new(type = nil)
      node = super
      node.event_node
      node
    end

    # Kill the event_node node before running inherit
    # @private
    def inherit(node)
      event_node.remove
      super
    end

    # Get the name of the node
    #
    # @return [String, nil]
    def node
      !purge? ? items_node[:node] : purge_node[:node]
    end

    # Get a list of retractions
    #
    # @return [Array<String>]
    def retractions
      items_node.find('//ns:retract', :ns => self.class.registered_ns).map do |i|
        i[:id]
      end
    end

    # Check if this is a retractions stanza
    #
    # @return [Boolean]
    def retractions?
      !retractions.empty?
    end

    # Get the list of items attached to this event
    #
    # @return [Array<Blather::Stanza::PubSub::PubSubItem>]
    def items
      items_node.find('//ns:item', :ns => self.class.registered_ns).map do |i|
        PubSubItem.new(nil,nil,self.document).inherit i
      end
    end

    # Check if this stanza has items
    #
    # @return [Boolean]
    def items?
      !items.empty?
    end

    # Check if this is a purge stanza
    #
    # @return [XML::Node, nil]
    def purge?
      purge_node
    end

    # Get or create the actual event node
    #
    # @return [Blather::XMPPNode]
    def event_node
      node = find_first('//ns:event', :ns => self.class.registered_ns)
      node = find_first('//event') unless node
      unless node
        (self << (node = XMPPNode.new('event', self.document)))
        node.namespace = self.class.registered_ns
      end
      node
    end

    # Get or create the actual items node
    #
    # @return [Blather::XMPPNode]
    def items_node
      node = find_first('ns:event/ns:items', :ns => self.class.registered_ns)
      unless node
        (self.event_node << (node = XMPPNode.new('items', self.document)))
        node.namespace = event_node.namespace
      end
      node
    end

    # Get the actual purge node
    #
    # @return [Blather::XMPPNode]
    def purge_node
      event_node.find_first('//ns:purge', :ns => self.class.registered_ns)
    end

    # Get the subscription IDs associated with this event
    #
    # @return [Array<String>]
    def subscription_ids
      find('//ns:header[@name="SubID"]', :ns => SHIM_NS).map do |n|
        n.content
      end
    end

    # Check if this is a subscription stanza
    #
    # @return [XML::Node, nil]
    def subscription?
      subscription_node
    end

    # Get the actual subscription node
    #
    # @return [Blather::XMPPNode]
    def subscription_node
      event_node.find_first('//ns:subscription', :ns => self.class.registered_ns)
    end
    alias_method :subscription, :subscription_node
  end  # Event

end  # PubSub
end  # Stanza
end  # Blather
