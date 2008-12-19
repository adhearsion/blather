module Blather
class Stanza
class Presence

  class Status < Presence
    VALID_STATES = [:away, :chat, :dnd, :xa]

    include Comparable

    register :status, :status

    def self.new(state = nil, message = nil)
      elem = super()
      elem.state = state
      elem.message = message
      elem
    end

    ##
    # Ensures type is nil or :unavailable
    def type=(type)
      raise ArgumentError, "Invalid type (#{type}). Must be nil or unavailable" if type && type.to_sym != :unavailable
      super
    end

    ##
    # Ensure state is one of :away, :chat, :dnd, :xa or nil
    def state=(state)
      state = state.to_sym if state
      state = nil if state == :available
      raise ArgumentError, "Invalid Status (#{state}), use: #{VALID_STATES*' '}" if state && !VALID_STATES.include?(state)

      remove_child :show
      self << XMPPNode.new('show', state) if state
    end

    ##
    # return:: :available if state is nil
    def state
      (type || content_from(:show) || :available).to_sym
    end

    ##
    # Ensure priority is between -128 and 127
    def priority=(new_priority)
      raise ArgumentError, 'Priority must be between -128 and +127' if new_priority && !(-128..127).include?(new_priority.to_i)

      remove_child :priority
      self << XMPPNode.new('priority', new_priority) if new_priority
    end

    def priority
      content_from(:priority).to_i
    end

    def message=(msg)
      remove_child :status
      self << XMPPNode.new('status', msg) if msg
    end

    def message
      content_from :status
    end

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