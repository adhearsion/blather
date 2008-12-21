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
    def self.register(type, name = nil, xmlns = nil)
      self.handler_heirarchy ||= []
      self.handler_heirarchy.unshift type

      name = name || self.name || type
      super name, xmlns
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
    # Creates a new Stanza with the name given
    # then attaches an ID and document (to enable searching)
    def self.new(elem_name = nil)
      elem = super
      elem.id = next_id
      XML::Document.new.root = elem
      elem
    end

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
      attributes.remove :id
      self['id'] = id if id
    end

    def id
      self['id']
    end

    def to=(to)
      attributes.remove :to
      self['to'] = to.to_s if to
    end

    ##
    # returns:: JID created from the "to" value of the stanza
    def to
      JID.new(self['to']) if self['to']
    end

    def from=(from)
      attributes.remove :from
      self['from'] = from.to_s if from
    end

    ##
    # returns:: JID created from the "from" value of the stanza
    def from
      JID.new(self['from']) if self['from']
    end

    def type=(type)
      attributes.remove :type
      self['type'] = type.to_s
    end

    ##
    # returns:: a symbol of the type
    def type
      self['type'].to_sym unless self['type'].nil? || self['type'].empty?
    end

  end
end