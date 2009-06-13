module Blather
class Stanza
class Presence

  # = Status Stanza
  #
  # Presence stanzas are used to express an entity's current network availability (offline or online, along with
  # various sub-states of the latter and optional user-defined descriptive text), and to notify other entities of
  # that availability.
  #
  # == State Attribute
  #
  # The +state+ attribute determains the availability of the entity and can be one of the following:
  #
  # * +:available+ -- The entity or resource is available
  # * +:away+ -- The entity or resource is temporarily away.
  # * +:chat+ -- The entity or resource is actively interested in chatting.
  # * +:dnd+ -- The entity or resource is busy (dnd = "Do Not Disturb").
  # * +:xa+ -- The entity or resource is away for an extended period (xa = "eXtended Away").
  #
  # Blather provides a helper for each possible state:
  #
  #   Status#available?
  #   Status#away?
  #   Status#chat?
  #   Status#dnd?
  #   Status#xa?
  #
  # Blather treats the +type+ attribute like a normal ruby object attribute providing a getter and setter.
  # The default +type+ is +available+.
  #
  #   status = Status.new
  #   status.state              # => :available
  #   status.available?         # => true
  #   status.state = :away
  #   status.away?              # => true
  #   status.available?         # => false
  #   status
  #   status.state = :invalid   # => RuntimeError
  #
  # == Type Attribute
  #
  # The +type+ attribute is inherited from Presence, but limits the value to either +nil+ or +:unavailable+
  # as these are the only types that relate to Status.
  #
  # == Priority Attribute
  #
  # The +priority+ attribute sets the priority of the status for the entity and must be an integer between
  # -128 and 127. 
  #
  # == Message Attribute
  #
  # The optional +message+ element contains XML character data specifying a natural-language description of
  # availability status. It is normally used in conjunction with the show element to provide a detailed
  # description of an availability state (e.g., "In a meeting").
  # 
  # Blather treats the +message+ attribute like a normal ruby object attribute providing a getter and setter.
  # The default +message+ is nil.
  #
  #   status = Status.new
  #   status.message            # => nil
  #   status.message = "gone!"
  #   status.message            # => "gone!"
  #
  class Status < Presence
    VALID_STATES = [:away, :chat, :dnd, :xa] # :nodoc:

    include Comparable

    register :status, :status

    def self.new(state = nil, message = nil)
      node = super()
      node.state = state
      node.message = message
      node
    end

    attribute_helpers_for(:state, [:available] + VALID_STATES)

    ##
    # Ensures type is nil or :unavailable
    def type=(type) # :nodoc:
      raise ArgumentError, "Invalid type (#{type}). Must be nil or unavailable" if type && type.to_sym != :unavailable
      super
    end

    ##
    # Ensure state is one of :available, :away, :chat, :dnd, :xa or nil
    def state=(state) # :nodoc:
      state = state.to_sym if state
      state = nil if state == :available
      raise ArgumentError, "Invalid Status (#{state}), use: #{VALID_STATES*' '}" if state && !VALID_STATES.include?(state)

      set_content_for :show, state
    end

    ##
    # :available if state is nil
    def state # :nodoc:
      (type || content_from(:show) || :available).to_sym
    end

    ##
    # Ensure priority is between -128 and 127
    def priority=(new_priority) # :nodoc:
      raise ArgumentError, 'Priority must be between -128 and +127' if new_priority && !(-128..127).include?(new_priority.to_i)
      set_content_for :priority, new_priority
      
    end

    content_attr_reader :priority, :to_i

    content_attr_accessor :message, nil, :status

    ##
    # Compare status based on priority
    # raises an error if the JIDs aren't the same
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
