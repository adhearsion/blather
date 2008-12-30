$:.unshift File.dirname(__FILE__)

require File.join(File.dirname(__FILE__), *%w[.. blather])

module Blather #:nodoc:

  class Client #:nodoc:
    attr_accessor :jid,
                  :roster

    def initialize
      @state = :initializing

      @status = Stanza::Presence::Status.new
      @handlers = {}
      @roster = Roster.new self

      setup_initial_handlers
    end

    def register_handler(type, &handler)
      @handlers[type] ||= []
      @handlers[type] << handler
    end

    def status
      @status.state
    end

    def status=(state)
      state, msg, to = state

      status = Stanza::Presence::Status.new state, msg
      status.to = to
      @status = status unless to

      write status
    end

    def write(data)
      @stream.send(data) if @stream
    end

    def stream_started(stream)
      @stream = stream

      #retreive roster
      write Stanza::Iq::Roster.new
    end

    def call(stanza)
      stanza.handler_heirarchy.each do |type|
        break if call_handler_for(type, stanza) && (stanza.is_a?(BlatherError) || stanza.type == :iq)
      end
    end

    def call_handler_for(type, stanza)
      if @handlers[type]
        @handlers[type].each { |handler| handler.call(stanza) }
        true
      end
    end

  protected
    def setup_initial_handlers
      register_handler :error do |err|
        raise err
      end

      register_handler :iq do |iq|
        write(Stanza::Error.new_from(iq, 'service-unavailable', :cancel).reply!) if [:set, :get].include?(iq.type)
      end

      register_handler :status do |status|
        roster[status.from].status = status if roster[status.from]
      end

      register_handler :roster do |node|
        roster.process node
        if @state == :initializing
          @state = :ready
          write @status
          call_handler_for :ready, nil
        end
      end
    end

  end #Client

  def client
    @client ||= Blather::Client.new
  end
  module_function :client

end #Blather

##
# Prepare server settings
#   setup [node@domain/resource], [password], [host], [port]
# host and port are optional defaulting to the domain in the JID and 5222 respectively
def setup(jid, password, host = nil, port = 5222)
  at_exit do
    trap(:INT) { EM.stop }
    EM.run { Blather::Stream.start Blather.client, jid, password, host, port }
  end
end

##
# Set handler for a stanza type
def handle(stanza_type, &block)
  Blather.client.register_handler stanza_type, &block
end

##
# Set current status
def status(state = nil, msg = nil)
  Blather.client.status = state, msg
end

##
# Direct access to the roster
def roster
  Blather.client.roster
end

##
# Write data to the stream
# Anything that resonds to #to_s can be paseed to the stream
def write(stanza)
  Blather.client.write(stanza)
end

##
# Helper method to make sending basic messages easier
#   say [jid], [msg]
def say(to, msg)
  Blather.client.write Blather::Stanza::Message.new(to, msg)
end

##
# Wrapper to grab the current JID
def jid
  Blather.client.jid
end
