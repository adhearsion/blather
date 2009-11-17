module Blather
class Stanza
class Presence

  # # Status Stanza
  #
  # [RFC 3921 Section 2.2.2 - Presence Child Elements](http://xmpp.org/rfcs/rfc3921.html#rfc.section.2.2.2)
  #
  # Presence stanzas are used to express an entity's current network
  # availability (offline or online, along with various sub-states of the
  # latter and optional user-defined descriptive text), and to notify other
  # entities of that availability.
  #
  # ## "State" Attribute
  #
  # The `state` attribute determains the availability of the entity and can be
  # one of the following:
  #
  # * `:available`  -- The entity or resource is available
  # * `:away`       -- The entity or resource is temporarily away.
  # * `:chat`       -- The entity or resource is actively interested in chatting.
  # * `:dnd`        -- The entity or resource is busy (dnd = "Do Not Disturb").
  # * `:xa`         -- The entity or resource is away for an extended period
  #                    (xa = "eXtended Away").
  #
  # Blather provides a helper for each possible state:
  #
  #     Status#available?
  #     Status#away?
  #     Status#chat?
  #     Status#dnd?
  #     Status#xa?
  #
  # Blather treats the `type` attribute like a normal ruby object attribute
  # providing a getter and setter. The default `type` is `available`.
  #
  #     status = Status.new
  #     status.state              # => :available
  #     status.available?         # => true
  #     status.state = :away
  #     status.away?              # => true
  #     status.available?         # => false
  #     status
  #     status.state = :invalid   # => RuntimeError
  #
  # ## "Type" Attribute
  #
  # The `type` attribute is inherited from Presence, but limits the value to
  # either `nil` or `:unavailable` as these are the only types that relate to
  # Status.
  #
  # ## "Priority" Attribute
  #
  # The `priority` attribute sets the priority of the status for the entity
  # and must be an integer between -128 and 127.
  #
  # ## "Message" Attribute
  #
  # The optional `message` element contains XML character data specifying a
  # natural-language description of availability status. It is normally used
  # in conjunction with the show element to provide a detailed description of
  # an availability state (e.g., "In a meeting").
  #
  # Blather treats the `message` attribute like a normal ruby object attribute
  # providing a getter and setter. The default `message` is nil.
  #
  #     status = Status.new
  #     status.message            # => nil
  #     status.message = "gone!"
  #     status.message            # => "gone!"
  #
  # @handler :status
  class Status < Presence
    VALID_STATES = [:away, :chat, :dnd, :xa].freeze

    include Comparable

    register :status, :status

    # Create a new Status stanza
    #
    # @param [<:away, :chat, :dnd, :xa>] state the state of the status
    # @param [#to_s] message a message to send with the status
    def self.new(state = nil, message = nil)
      node = super()
      node.state = state
      node.message = message
      node
    end

    # Check if the state is available
    #
    # @return [true, false]
    def available?
      self.state == :available
    end

    # Check if the state is away
    #
    # @return [true, false]
    def away?
      self.state == :away
    end

    # Check if the state is chat
    #
    # @return [true, false]
    def chat?
      self.state == :chat
    end

    # Check if the state is dnd
    #
    # @return [true, false]
    def dnd?
      self.state == :dnd
    end

    # Check if the state is xa
    #
    # @return [true, false]
    def xa?
      self.state == :xa
    end

    # Set the type attribute
    # Ensures type is nil or :unavailable
    #
    # @param [<:unavailable, nil>] type the type
    def type=(type)
      if type && type.to_sym != :unavailable
        raise ArgumentError, "Invalid type (#{type}). Must be nil or unavailable"
      end
      super
    end

    # Set the state
    # Ensure state is one of :available, :away, :chat, :dnd, :xa or nil
    #
    # @param [<:available, :away, :chat, :dnd, :xa, nil>] state
    def state=(state) # :nodoc:
      state = state.to_sym if state
      state = nil if state == :available
      if state && !VALID_STATES.include?(state)
        raise ArgumentError, "Invalid Status (#{state}), use: #{VALID_STATES*' '}"
      end

      set_content_for :show, state
    end

    # Get the state of the status
    #
    # @return [<:available, :away, :chat, :dnd, :xa>]
    def state
      state = type || content_from(:show)
      state = :available if state.blank?
      state.to_sym
    end

    # Set the priority of the status
    # Ensures priority is between -128 and 127
    #
    # @param [Fixnum<-128...127>] new_priority
    def priority=(new_priority) # :nodoc:
      if new_priority && !(-128..127).include?(new_priority.to_i)
        raise ArgumentError, 'Priority must be between -128 and +127'
      end
      set_content_for :priority, new_priority
    end

    # Get the priority of the status
    #
    # @return [Fixnum<-128...127>]
    def priority
      read_content(:priority).to_i
    end

    # Get the status message
    #
    # @return [String, nil]
    def message
      read_content :status
    end

    # Set the status message
    #
    # @param [String, nil] message
    def message=(message)
      set_content_for :status, message
    end

    # Compare status based on priority
    # raises an error if the JIDs aren't the same
    #
    # @param [Blather::Stanza::Presence::Status] o
    # @return [true,false]
    def <=>(o)
      unless self.from && o.from && self.from.stripped == o.from.stripped
        raise ArgumentError, "Cannot compare status from different JIDs: #{[self.from, o.from].inspect}"
      end
      self.priority <=> o.priority
    end

  end #Status

end #Presence
end #Stanza
end #Blather
