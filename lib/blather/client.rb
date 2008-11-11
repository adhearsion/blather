require File.join(File.dirname(__FILE__), %w[.. blather])

module Blather

  class Client
    @@callbacks = {}
    @@status = nil

    attr_accessor :jid,
                  :roster

    def send_data(data)
      @stream.send data
    end

    def status
      @@status
    end

    def set_status(state = nil, msg = nil, to = nil)
      status = Presence::Status.new state, msg
      status.to = to
      @@status = status unless to

      send_data status
    end

    def stream_started(stream)
      @stream = stream
      retreive_roster
    end

    def call(stanza)
      stanza.callback_heirarchy.each { |type| break if callback(type, stanza) }
    end

    # Default response to an Iq 'get' or 'set' is 'service-unavailable'/'cancel'
    def receive_iq(iq)
      send_data(ErrorStanza.new_from(iq, 'service-unavailable', 'cancel').reply!) if [:set, :get].include?(iq.type)
    end

    def receive_roster(node)
      if !@roster && node.type == :result
        self.roster = Roster.new(@stream, node)
        register_callback(:status, -128) { |_, status| roster[status.from].status = status if roster[status.from]; false }
        set_status
      elsif node.type == :set
        roster.process node
      end
    end

    def self.register_callback(type, priority = 0, &callback)
      @@callbacks[type] ||= []
      @@callbacks[type] << Callback.new(priority, &callback)
      @@callbacks[type].sort!
    end

    def register_callback(type, priority = 0, &callback)
      self.class.register_callback(type, priority = 0, &callback)
    end

    def self.status(state = nil, msg = nil)
      @@status = Presence::Status.new state, msg
    end

    def callback(type, stanza)
      complete = false
      (@@callbacks[type] || []).each { |callback| break if complete = callback.call(self, stanza) }

      method = "receive_#{type}"
      complete = __send__(method, stanza) if !complete && respond_to?(method)
      complete
    end

    def retreive_roster
      send_data Iq::Roster.new
    end

  end #Client

end
