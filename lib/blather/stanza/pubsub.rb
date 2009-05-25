module Blather
class Stanza

  autoload :Subscriber, 'lib/blather/stanza/pubsub/subscriber'

  class PubSub < Iq
    register :pubsub, :pubsub, 'http://jabber.org/protocol/pubsub'

    include Subscriber

    def self.import(node)
      klass = nil
      if node.doc.find_first('//pubsub_ns:pubsub[not(pubsub_ns:subscription or pubsub_ns:unsubscribe)]', :pubsub_ns => self.ns)
        node.find_first('//pubsub_ns:pubsub', :pubsub_ns => self.ns).children.each do |e|
          break if klass = class_from_registration(e.element_name, e.namespaces.namespace.to_s)
        end
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
      pubsub.remove
      super
    end

    def pubsub
      unless p = find_first('pubsub_ns:pubsub', :pubsub_ns => self.class.registered_ns)
        self << (p = XMPPNode.new('pubsub', self.document))
        p.namespace = self.class.registered_ns
      end
      p
    end
  end

  class PubSubItem < XMPPNode
    def self.new(id = nil, payload = nil)
      new_node = super 'item'
      new_node.id = id
      new_node.payload = payload
      new_node
    end

    attribute_accessor :id, :to_sym => false

    def payload=(payload = nil)
      self.content = (payload ? payload : '')
    end

    def payload
      content.empty? ? nil : content
    end
  end

end #Stanza
end #Blather
