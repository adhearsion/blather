module Blather
class Stanza

  # # PubSubOwner Base Class
  #
  # [XEP-0060 - Publish-Subscribe](http://xmpp.org/extensions/xep-0060.html)
  #
  # @handler :pubsub_owner
  class PubSubOwner < Iq
    register :pubsub_owner, :pubsub, 'http://jabber.org/protocol/pubsub#owner'

    # Creates the proper class from the stana's child
    # @private
    def self.import(node)
      klass = nil
      if pubsub = node.document.at_xpath('//ns:pubsub', :ns => self.registered_ns)
        pubsub.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
      end
      (klass || self).new(node[:type]).inherit(node)
    end

    # Overrides the parent to ensure a pubsub node is created
    # @private
    def self.new(type = nil, host = nil)
      new_node = super type
      new_node.to = host
      new_node.pubsub
      new_node
    end

    # Overrides the parent to ensure the pubsub node is destroyed
    # @private
    def inherit(node)
      remove_children :pubsub
      super
    end

    # Get or create the pubsub node on the stanza
    #
    # @return [Blather::XMPPNode]
    def pubsub
      unless p = at_xpath('ns:pubsub', :ns => self.class.registered_ns)
        self << (p = XMPPNode.new('pubsub', self.document))
        p.namespace = self.class.registered_ns
      end
      p
    end
  end  # PubSubOwner

end  # Stanza
end  # Blather
