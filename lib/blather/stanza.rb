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
    def self.register(handler, name = nil, ns = nil)
      @@handler_list << handler
      self.handler_heirarchy ||= []
      self.handler_heirarchy.unshift handler

      name = name || self.registered_name || handler
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
    def self.new(name = nil)
      node = super
      node.name = name.to_s if name
      node
    end

    ##
    # Helper method to generate stanza guard methods
    #
    # attribute_helpers_for(:type, [:subscribe, :unsubscribe])
    #
    # This generates "subscribe?" and "unsubscribe?" methods that return
    # true if self.type == :subscribe or :unsubscribe, respectively.
    def self.attribute_helpers_for(attr, values)
      [values].flatten.each do |v|
        define_method("#{v}?") { __send__(attr) == v }
      end
    end

    attribute_helpers_for(:type, :error)

    ##
    # Copies itself then swaps from and to
    # then returns the new stanza
    def reply
      self.dup.reply!
    end

    ##
    # Swaps from and to
    def reply!
      self.to, self.from = self.from, self.to
      self
    end

    attribute_accessor :id

    attribute_writer :to, :from

    ##
    # returns:: JID created from the "to" value of the stanza
    def to
      JID.new(self[:to]) if self[:to]
    end

    ##
    # returns:: JID created from the "from" value of the stanza
    def from
      JID.new(self[:from]) if self[:from]
    end

    attribute_accessor :type, :call => :to_sym

    ##
    # Transform the stanza into a stanza error
    # <tt>err_name_or_class</tt> can be the name of the error or the error class to use
    # <tt>type</tt>, <tt>text</tt>, <tt>extras</tt> are the same as for StanzaError#new
    def as_error(name, type, text = nil, extras = [])
      StanzaError.new self, name, type, text, extras
    end

    protected
    def reply_if_needed!
      unless @reversed_endpoints
        reply!
        @reversed_endpoints = true
      end
      self
    end
  end
end
