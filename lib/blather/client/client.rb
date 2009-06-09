require File.join(File.dirname(__FILE__), *%w[.. .. blather])

module Blather #:nodoc:

  class Client #:nodoc:
    attr_reader :jid,
                :roster

    def initialize
      @state = :initializing

      @status = Stanza::Presence::Status.new
      @handlers = {}
      @tmp_handlers = {}
      @roster = Roster.new self

      setup_initial_handlers
    end

    def jid=(new_jid)
      @jid = JID.new new_jid
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

    def setup?
      @setup.is_a? Array
    end

    def setup(jid, password, host = nil, port = nil)
      @jid = JID.new(jid)
      @setup = [@jid, password]
      @setup << host if host
      @setup << port if port
      self
    end

    def run
      raise 'not setup!' unless setup?
      klass = @setup[0].node ? Blather::Stream::Client : Blather::Stream::Component
      @stream = klass.start self, *@setup
    end

    def register_tmp_handler(id, &handler)
      @tmp_handlers[id] = handler
    end

    def register_handler(type, *guards, &handler)
      check_guards guards
      @handlers[type] ||= []
      @handlers[type] << [guards, handler]
    end

    def write(stanza)
      @stream.send(stanza) if @stream
    end

    def write_with_handler(stanza, &handler)
      register_tmp_handler stanza.id, &handler
      write stanza
    end

    def post_init
      self.jid.node ? client_post_init : ready!
    end

    def close
      @stream.close_connection_after_writing
    end

    def unbind
      EM.stop if EM.reactor_running?
    end

    def receive_data(stanza)
      if handler = @tmp_handlers.delete(stanza.id)
        handler.call stanza
      else
        stanza.handler_heirarchy.each do |type|
          break if call_handler_for(type, stanza)# && (stanza.is_a?(BlatherError) || stanza.type == :iq)
        end
      end
    end

  protected
    def setup_initial_handlers
      register_handler :error do |err|
        raise err
      end

      register_handler :iq, :type => [:get, :set] do |iq|
        write(StanzaError.new(iq, 'service-unavailable', :cancel).to_node)
      end

      register_handler :status do |status|
        roster[status.from].status = status if roster[status.from]
      end

      register_handler :roster do |node|
        roster.process node
      end
    end

    def ready!
      @state = :ready
      call_handler_for :ready, nil
    end

    def client_post_init
      write_with_handler Stanza::Iq::Roster.new do |node|
        roster.process node
        write @status
        ready!
      end
    end

    def call_handler_for(type, stanza)
      if @handlers[type]
        @handlers[type].find do |guards, handler|
          if guards.first.is_a?(String)
            unless (result = stanza.find(*guards)).empty?
              handler.call(stanza, result)
            end
          elsif !guarded?(guards, stanza)
            handler.call(stanza)
          end
        end
      end
    end

    ##
    # If any of the guards returns FALSE this returns true
    # the logic is reversed to allow short circuiting
    # (why would anyone want to loop over more values than necessary?)
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
            if test.class.respond_to?(:last_match)
              !(test =~ value)
            elsif test.is_a?(Array)
              !test.include? value
            else
              test != value
            end
          end
        when Proc
          !guard.call(stanza)
        end
      end
    end

    def check_guards(guards)
      guards.each do |guard|
        case guard
        when Array
          guard.each { |g| check_guards([g]) }
        when Symbol, Proc, Hash, String
          nil
        else
          raise "Bad guard: #{guard.inspect}"
        end
      end
    end

  end #Client
end #Blather
