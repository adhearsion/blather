module Blather

  # # Base XMPP Stanza
  #
  # All stanzas inherit this class. It provides a set of methods and helpers
  # common to all XMPP Stanzas
  #
  # @handler :stanza
  class Stanza < XMPPNode
    # @private
    @@last_id = 0
    # @private
    @@handler_list = []

    class_inheritable_array :handler_heirarchy

    # Registers a callback onto the callback stack
    #
    # @param [Symbol] handler the name of the handler
    # @param [Symbol, String, nil] name the name of the first element in the
    #        stanza. If nil the inherited name will be used. If that's nil the
    #        handler name will be used.
    # @param [String, nil] ns the namespace of the stanza
    def self.register(handler, name = nil, ns = nil)
      @@handler_list << handler
      self.handler_heirarchy ||= [:stanza]
      self.handler_heirarchy.unshift handler

      name = name || self.registered_name || handler
      super name, ns
    end

    # The handler stack for the current stanza class
    #
    # @return [Array<Symbol>]
    def self.handler_list
      @@handler_list
    end

    # Helper method that creates a unique ID for stanzas
    #
    # @return [String] a new unique ID
    def self.next_id
      @@last_id += 1
      'blather%04x' % @@last_id
    end

    # Check if the stanza is an error stanza
    #
    # @return [true, false]
    def error?
      self.type == :error
    end

    # Creates a copy with to and from swapped
    #
    # @return [Blather::Stanza]
    def reply
      self.dup.reply!
    end

    # Swaps from and to
    #
    # @return [self]
    def reply!
      self.to, self.from = self.from, self.to
      self
    end

    # Get the stanza's ID
    #
    # @return [String, nil]
    def id
      read_attr :id
    end

    # Set the stanza's ID
    #
    # @param [#to_s] id the new stanza ID
    def id=(id)
      write_attr :id, id
    end

    # Get the stanza's to
    #
    # @return [Blather::JID, nil]
    def to
      JID.new(self[:to]) if self[:to]
    end

    # Set the stanza's to field
    #
    # @param [#to_s] to the new JID for the to field
    def to=(to)
      write_attr :to, to
    end

    # Get the stanza's from
    #
    # @return [Blather::JID, nil]
    def from
      JID.new(self[:from]) if self[:from]
    end

    # Set the stanza's from field
    #
    # @param [#to_s] from the new JID for the from field
    def from=(from)
      write_attr :from, from
    end

    # Get the stanza's type
    #
    # @return [Symbol, nil]
    def type
      read_attr :type, :to_sym
    end

    # Set the stanza's type
    #
    # @param [#to_s] type the new stanza type
    def type=(type)
      write_attr :type, type
    end

    # Create an error stanza from the current stanza
    #
    # @param [String] name the error name
    # @param [<Blather::StanzaError::VALID_TYPES>] type the error type
    # @param [String, nil] text the error text
    # @param [Array<XML::Node>] extras an array of extra nodes to attach to
    # the error
    #
    # @return [Blather::StanzaError]
    def as_error(name, type, text = nil, extras = [])
      StanzaError.new self, name, type, text, extras
    end

  protected
    # @private
    def reply_if_needed!
      unless @reversed_endpoints
        reply!
        @reversed_endpoints = true
      end
      self
    end
  end
end
