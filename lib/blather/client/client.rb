require File.join(File.dirname(__FILE__), *%w[.. .. blather])

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

    def setup?
      @setup.is_a? Array
    end

    def setup(jid, password, host = nil, port = nil)
      @setup = [JID.new(jid), password]
      @setup << host if host
      @setup << port if port
      self
    end

    def run
      raise 'not setup!' unless setup?
      trap(:INT) { EM.stop }
      trap(:TERM) { EM.stop }
      LOG.info "Starting..."
      EM.run {
        klass = @setup[0].node ? Blather::Stream::Client : Blather::Stream::Component
        klass.start self, *@setup
      }
      LOG.info "Exiting..."
    end

    def register_tmp_handler(id, &handler)
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
      @status = status unless to

      write status
    end

    def write(stanza)
      stanza.from ||= jid if stanza.respond_to?(:from)
      @stream.send(stanza) if @stream
    end

    def write_with_handler(stanza, &hanlder)
      register_tmp_handler stanza.id, &handler
      write stanza
    end

    def stream_started(stream)
      @stream = stream

      #retreive roster
      if @stream.is_a?(Stream::Component)
        @state = :ready
        call_handler_for :ready, nil
      else
        r = Stanza::Iq::Roster.new
        register_tmp_handler r.id do |node|
          roster.process node
          @state = :ready
          write @status
          call_handler_for :ready, nil
        end
        write r
      end
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
        write(StanzaError.new(iq, 'service-unavailable', :cancel).to_node) if [:set, :get].include?(iq.type)
      end

      register_handler :status do |status|
        roster[status.from].status = status if roster[status.from]
      end

      register_handler :roster do |node|
        roster.process node
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
          guard.find do |method, test|
            value = stanza.__send__(method)
            case test
            when Regexp
              !value.to_s.match(test)
            when Array
              !test.include? value
            else
              test != value
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
end #Blather
