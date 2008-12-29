module Blather
  ##
  # Base XMPP Stanza
  class Stanza < XMPPNode
    @@last_id = 0

    class_inheritable_array :handler_heirarchy

    ##
    # Registers a callback onto the callback heirarchy stack
    #
    # Thanks to help from ActiveSupport every class
    # that inherits Stanza can register a callback for itself
    # which is added to a list and iterated over when looking for
    # a callback to use
    def self.register(type, name = nil, ns = nil)
      self.handler_heirarchy ||= []
      self.handler_heirarchy.unshift type

      name = name || self.name || type
      super name, ns
    end

    ##
    # Helper method that creates a unique ID for stanzas
    def self.next_id
      @@last_id += 1
      'blather%04x' % @@last_id
    end

    ##
    # Creates a new stanza with the same name as the node
    # then inherits all the node's attributes and properties
    def self.import(node)
      self.new(node.element_name).inherit(node)
    end

    ##
    # Automatically set the stanza's ID
    # and attach it to a document so XPath searching works
    def initialize(name = nil)
      super
      XML::Document.new.root = self
      self.name = name.to_s if name
      self.id = self.class.next_id
    end

    ##
    # Helper method to ask the object if it's an error
    def error?
      self.type == :error
    end

    ##
    # Copies itself then swaps from and to
    # then returns the new stanza
    def reply
      self.copy(true).reply!
    end

    ##
    # Swaps from and to
    def reply!
      self.to, self.from = self.from, self.to
      self
    end

    def id=(id)
      attributes[:id] = id
    end

    def id
      attributes[:id]
    end

    def to=(to)
      attributes[:to] = to
    end

    ##
    # returns:: JID created from the "to" value of the stanza
    def to
      JID.new(attributes[:to]) if attributes[:to]
    end

    def from=(from)
      attributes[:from] = from
    end

    ##
    # returns:: JID created from the "from" value of the stanza
    def from
      JID.new(attributes[:from]) if attributes[:from]
    end

    def type=(type)
      attributes[:type] = type
    end

    ##
    # returns:: a symbol of the type
    def type
      attributes[:type].to_sym unless attributes[:type].blank?
    end

  end
end