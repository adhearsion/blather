module Blather
class Stanza

  # # Pubsub Stanza
  #
  # [XEP-0060 - Publish-Subscribe](http://xmpp.org/extensions/xep-0060.html)
  #
  # The base class for all PubSub nodes. This provides helper methods common to
  # all PubSub nodes.
  #
  # @handler :pubsub_node
  class PubSub < Iq
    register :pubsub_node, :pubsub, 'http://jabber.org/protocol/pubsub'

    # @private
    def self.import(node)
      klass = nil
      if pubsub = node.document.find_first('//ns:pubsub', :ns => self.registered_ns)
        pubsub.children.detect do |e|
          ns = e.namespace ? e.namespace.href : nil
          klass = class_from_registration(e.element_name, ns)
        end
      end
      (klass || self).new(node[:type]).inherit(node)
    end

    # Overwrites the parent constructor to ensure a pubsub node is present.
    # Also allows the addition of a host attribute
    #
    # @param [<Blather::Stanza::Iq::VALID_TYPES>] type the IQ type
    # @param [String, nil] host the host the node should be sent to
    def self.new(type = nil, host = nil)
      new_node = super type
      new_node.to = host
      new_node.pubsub
      new_node
    end

    # Overrides the parent to ensure the current pubsub node is destroyed before
    # inheritting the new content
    #
    # @private
    def inherit(node)
      remove_children :pubsub
      super
    end

    # Get or create the pubsub node on the stanza
    #
    # @return [Blather::XMPPNode]
    def pubsub
      p = find_first('ns:pubsub', :ns => self.class.registered_ns) ||
          find_first('pubsub', :ns => self.class.registered_ns)

      unless p
        self << (p = XMPPNode.new('pubsub', self.document))
        p.namespace = self.class.registered_ns
      end
      p
    end
  end  # PubSub

  # # PubSubItem Fragment
  #
  # This fragment is found in many places throughout the pubsub spec
  # This is a convenience class to attach methods to the node
  class PubSubItem < XMPPNode
    ATOM_NS = 'http://www.w3.org/2005/Atom'.freeze

    # Create a new PubSubItem
    #
    # @param [String, nil] id the id of the stanza
    # @param [#to_s, nil] payload the payload to attach to this item.
    # @param [XML::Document, nil] document the document the node should be
    # attached to. This should be the document of the parent PubSub node.
    def self.new(id = nil, payload = nil, document = nil)
      new_node = super 'item', document
      new_node.id = id
      new_node.payload = payload if payload
      new_node
    end

    # Get the item's ID
    #
    # @return [String, nil]
    def id
      read_attr :id
    end

    # Set the item's ID
    #
    # @param [#to_s] id the new ID
    def id=(id)
      write_attr :id, id
    end

    # Get the item's payload
    #
    # @return [String, Blather::Stanza::AtomEntry, nil]
    def payload
      self.content.empty? ? nil : content
    end

    # Set the item's payload
    #
    # @param [String, Blather::Stanza::AtomEntry, nil] payload the payload
    def payload=(payload)
      if payload.class == AtomEntry
        self << payload
      else
        self.content = payload
      end
    end
  end  # PubSubItem
  
  class AtomEntry < XMPPNode
    register :entry, 'http://www.w3.org/2005/Atom'

    # Create a new AtomEntry
    #
    # @param [String, nil] content the content of the entry
    def self.new(content)
      new_node = super 'entry'
      new_node.content = content if content
      new_node
    end
  end  # AtomEntry

end  # Stanza
end  # Blather
