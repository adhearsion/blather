module Blather
class Stanza

  class PubSub < Iq
    register :pubsub_node, :pubsub, 'http://jabber.org/protocol/pubsub'

    def self.import(node)
      klass = nil
      if pubsub = node.document.find_first('//ns:pubsub', :ns => self.registered_ns)
        pubsub.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
      end
      (klass || self).new(node[:type]).inherit(node)
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
      p = find_first('ns:pubsub', :ns => self.class.registered_ns) ||
          find_first('pubsub', :ns => self.class.registered_ns)

      unless p
        self << (p = XMPPNode.new('pubsub', self.document))
        p.namespace = self.class.registered_ns
      end
      p
    end
  end

  class PubSubItem < XMPPNode
    def self.new(id = nil, payload = nil, document = nil)
      new_node = super 'item', document
      new_node.id = id
      new_node.payload = payload if payload
      new_node
    end

    attribute_accessor :id

    def payload=(payload = nil)
      self.entry.content = payload
    end

    def payload
      self.entry.content.empty? ? nil : content
    end

    def entry
      e = find_first('ns:entry', :ns => 'http://www.w3.org/2005/Atom') ||
          find_first('entry', :ns => 'http://www.w3.org/2005/Atom')

      unless e
        self << (e = XMPPNode.new('entry', self.document))
        e.namespace = 'http://www.w3.org/2005/Atom'
      end
      e
    end
  end

end #Stanza
end #Blather
