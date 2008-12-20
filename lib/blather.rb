$:.unshift File.dirname(__FILE__)

%w[
  rubygems
  xml/libxml
  eventmachine
  digest/md5
  logger

  blather/errors
  blather/jid
  blather/roster
  blather/roster_item
  blather/sugar
  blather/xmpp_node

  blather/stanza
  blather/stanza/error
  blather/stanza/iq
  blather/stanza/iq/query
  blather/stanza/iq/roster
  blather/stanza/message
  blather/stanza/presence
  blather/stanza/presence/status
  blather/stanza/presence/subscription

  blather/stream
  blather/stream/parser
  blather/stream/resource
  blather/stream/sasl
  blather/stream/session
  blather/stream/tls
].each { |r| require r }

XML.indent_tree_output = false

module Blather
  VERSION = '0.1'
  LOG = Logger.new(STDOUT)

  class Client
    attr_accessor :jid,
                  :roster

    def initialize
      @state = :initializing

      @status = Stanza::Presence::Status.new
      @handlers = Hash.new { |h,k| h[k] = [] }
      @roster = Roster.new self

      setup_initial_handlers
    end

    def register_handler(type, &handler)
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
        break if call_handler_for(type, stanza) && stanza.type == :iq
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
      register_handler :iq do |iq|
        write(Stanza::Error.new_from(iq, 'service-unavailable', 'cancel').reply!) if [:set, :get].include?(iq.type)
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

  module Application
    @@client = Blather::Client.new

    def setup(jid, password, host = nil, port = 5222)
      at_exit do
        trap(:INT) { EM.stop }
        EM.run { Blather::Stream.start @@client, Blather::JID.new(jid), password, host, port }
      end
    end

    def daemonize
      @daemonize = true
    end

    def handle(stanza_type, &block)
      @@client.register_handler stanza_type, &block
    end

    def status(state = nil, msg = nil)
      @@client.status = state, msg
    end

    def roster
      @@client.roster
    end

    def write(stanza)
      @@client.write(stanza)
    end

    def say(to, msg)
      @@client.write Blather::Stanza::Message.new(to, msg)
    end
  end #Application

end

include Blather::Application