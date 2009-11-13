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

    def error?
      self.type == :error
    end

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

    def id
      read_attr :id
    end

    def id=(id)
      write_attr :id, id
    end

    def to=(to)
      write_attr :to, to
    end

    def from=(from)
      write_attr :from, from
    end

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

    def type
      read_attr :type, :to_sym
    end

    def type=(type)
      write_attr :type, type
    end

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
