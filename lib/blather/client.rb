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
      @tmp_handlers = {}
      @roster = Roster.new self

      setup_initial_handlers
    end

    def temporary_handler(id, &handler)
      @tmp_handlers[id] = handler
    end

    def register_handler(type, *guards, &handler)
      @handlers[type] ||= []
      @handlers[type] << [guards, handler]
    end

    def status
      @status.state
    end

    def status=(state)
      state, msg, to = state

      status = Stanza::Presence::Status.new state, msg
      status.to = to
      @statustatus unless to

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

    def stop
      @stream.close_connection_after_writing
    end

    def stopped
      EM.stop
    end

    def call(stanza)
      if handler = @tmp_handlers.delete(stanza.id)
        handler.call stanza
      else
        stanza.handler_heirarchy.each do |type|
          break if call_handler_for(type, stanza) && (stanza.is_a?(BlatherError) || stanza.type == :iq)
        end
      end
    end

    def call_handler_for(type, stanza)
      if @handlers[type]
        @handlers[type].find { |guards, handler| handler.call(stanza) unless guarded?(guards, stanza) }
        true
      end
    end

  protected
    def setup_initial_handlers
      register_handler :error do |err|
        raise err
      end

      register_handler :iq do |iq|
        write(StanzaError::ServiceUnavailable.new(iq, :cancel).to_node) if [:set, :get].include?(iq.type)
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

    ##
    # If any of the guards returns FALSE this returns true
    def guarded?(guards, stanza)
      guards.find do |guard|
        case guard
        when Symbol
          !stanza.__send__(guard)
        when Array
          # return FALSE if any item is TRUE
          !guard.detect { |condition| !guarded?([condition], stanza) }
        when Hash
          # return FALSE unless any inequality is found
          guard.find do |method, value|
            if value.is_a?(Regexp)
              !stanza.__send__(method).to_s.match(value)
            else
              stanza.__send__(method) != value
            end
          end
        when Proc
          !guard.call(stanza)
        else
          raise "Bad guard: #{guard.inspect}"
        end
      end
    end

  end #Client

  def client
    @client ||= Client.new
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
# Shutdown the connection.
# Flushes the write buffer then stops EventMachine
def shutdown
  Blather.client.stop
end

##
# Set handler for a stanza type
def handle(stanza_type, *guards, &block)
  Blather.client.register_handler stanza_type, *guards, &block
end

##
# Wrapper for "handle :ready" (just a bit of syntactic sugar)
def when_ready(&block)
  handle :ready, &block
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

##
# Checks to see if the method is part of the handlers list.
# If so it creates a handler, otherwise it'll pass it back
# to Ruby's method_missing handler
def method_missing(method, *args, &block)
  if Blather::Stanza.handler_list.include?(method)
    handle method, *args, &block
  else
    super
  end
end
