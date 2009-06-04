module Blather
class Stanza

  class PubSubOwner < Iq
    register :pubsub_owner, :pubsub, 'http://jabber.org/protocol/pubsub#owner'

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
      unless p = find_first('ns:pubsub', :ns => self.class.registered_ns)
        self << (p = XMPPNode.new('pubsub', self.document))
        p.namespace = self.class.registered_ns
      end
      p
    end
  end

end #Stanza
end #Blather
