module Blather
  ##
  # Base XMPP Stanza
  class Stanza < XMPPNode
    @@last_id = 0
    @@handler_list = []

    class_inheritable_array :handler_heirarchy

    ##
    # Registers a callback onto the callback heirarchy stack
    #
    # Thanks to help from ActiveSupport every class
    # that inherits Stanza can register a callback for itself
    # which is added to a list and iterated over when looking for
    # a callback to use
    def self.register(type, name = nil, ns = nil)
      @@handler_list << type
      self.handler_heirarchy ||= []
      self.handler_heirarchy.unshift type

      name = name || self.name || type
      super name, ns
    end

    def self.handler_list
      @@handler_list
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

    attribute_accessor :id, :to_sym => false

    attribute_writer :to, :from

    ##
    # returns:: JID created from the "to" value of the stanza
    def to
      JID.new(attributes[:to]) if attributes[:to]
    end

    ##
    # returns:: JID created from the "from" value of the stanza
    def from
      JID.new(attributes[:from]) if attributes[:from]
    end

    attribute_accessor :type

    ##
    # Transform the stanza into a stanza error
    # <tt>err_name_or_class</tt> can be the name of the error or the error class to use
    # <tt>type</tt>, <tt>text</tt>, <tt>extras</tt> are the same as for StanzaError#new
    def as_error(err_name_or_class, type, text = nil, extras = [])
      klass = (err_name_or_class.is_a?(Class) ? err_name_or_class : StanzaError.class_from_registration(err_name_or_class))
      klass.new self, type, text, extras
    end
  end
end