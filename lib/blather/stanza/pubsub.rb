module Blather
class Stanza

  class PubSub < Iq
    register :pubsub, :pubsub, 'http://jabber.org/protocol/pubsub'

    def self.import(node)
      klass = nil
      node.find_first('//pubsub_ns:pubsub', :pubsub_ns => self.ns).children.each do |e|
        break if klass = class_from_registration(e.element_name, e.namespaces.default.to_s)
      end
      (klass || self).new(node.attributes[:type]).inherit(node)
    end

    ##
    # Ensure the namespace is set to the query node
    def initialize(type = nil, host = nil)
      super type
      self.to = host
      pubsub.namespace = self.class.ns unless pubsub.namespace
    end

    ##
    # Kill the pubsub node before running inherit
    def inherit(node)
      pubsub.remove!
      super
    end

    def pubsub
      unless p = find_first('//pubsub', self.class.ns)
        p = XMPPNode.new('pubsub')
        p.namespace = self.class.ns
        self << p
      end
      p
    end
  end

  class PubSubItem < XMPPNode
    def initialize(id = nil, payload = nil)
      super 'item'
      self.id = id
      self.payload = payload
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
