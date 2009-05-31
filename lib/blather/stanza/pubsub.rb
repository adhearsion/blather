module Blather
class Stanza

  autoload :Subscriber, 'lib/blather/stanza/pubsub/subscriber'

  class PubSub < Iq
    register :pubsub_node, :pubsub, 'http://jabber.org/protocol/pubsub'

    include Subscriber

    def self.import(node)
      klass = nil
      if pubsub = node.document.find_first('//ns:pubsub[not(ns:subscribe or ns:subscription or ns:unsubscribe)]', :ns => self.registered_ns)
        pubsub.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
      end
      (klass || self).new(node.attributes[:type]).inherit(node)
    end

    ##
    # Ensure the namespace is set to the query node
    def self.new(type = nil, host = nil)
      new_node = super type
      new_node.to = host
      new_node.pubsub
      new_node
    end

    ##
    # Kill the pubsub node before running inherit
    def inherit(node)
      remove_children :pubsub
      super
    end

    def pubsub
      p = if self.class.registered_ns
        find_first('ns:pubsub', :ns => self.class.registered_ns) ||
        find_first('pubsub', :ns => self.class.registered_ns)
      else
        find_first('pubsub')
      end

      unless p
        self << (p = XMPPNode.new('pubsub', self.document))
        p.namespace = self.class.registered_ns
      end
      p
    end

    def items
      items_node.find('ns:item', :ns => self.class.registered_ns).map { |i| PubSubItem.new.inherit i }
    end
  end

  class PubSubItem < XMPPNode
    def self.new(id = nil, payload = nil)
      new_node = super 'item'
      new_node.id = id
      new_node.payload = payload
      new_node
    end

    attribute_accessor :id

    def payload=(payload = nil)
      self.content = (payload ? payload : '')
    end

    def payload
      content.empty? ? nil : content
    end
  end

end #Stanza
end #Blather
