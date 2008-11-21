module Blather
class Stanza
class Presence

  class Status < Presence
    include Comparable

    register :status

    def self.new(state = nil, message = nil)
      elem = super()
      elem.state = state
      elem.message = message
      elem
    end

    def type=(type)
      raise ArgumentError, "Invalid type (#{type}). Must be nil or unavailable" if type && type.to_sym != :unavailable
      super
    end

    VALID_STATES = [:away, :chat, :dnd, :xa].freeze
    def state=(state)
      state = state.to_sym if state
      state = nil if state == :available
      raise ArgumentError, "Invalid Status (#{state}), use: #{VALID_STATES*' '}" if state && !VALID_STATES.include?(state)

      remove_child :show
      self << XMPPNode.new('show', state) if state
    end

    def state
      (type || content_from(:show) || :available).to_sym
    end

    def priority=(priority)
      raise ArgumentError, 'Priority must be between -128 and +127' if priority && !(-128..127).include?(priority.to_i)

      remove_child :priority
      self << XMPPNode.new('priority', priority) if priority
    end

    def priority
      @priority ||= content_from(:priority).to_i
    end

    def message=(msg)
      remove_child :status
      self << XMPPNode.new('status', msg) if msg
    end

    def message
      content_from :status
    end

    def <=>(o)
      raise "Cannot compare status from different JIDs: #{[self.from, o.from].inspect}" unless self.from.stripped == o.from.stripped
      self.priority <=> o.priority
    end

  end #Status

end #Presence
end #Stanza
end