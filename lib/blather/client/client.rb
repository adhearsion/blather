require File.join(File.dirname(__FILE__), *%w[.. .. blather])

module Blather #:nodoc:

  # = Blather Client
  #
  # Blather's Client class provides a set of helpers for working with common XMPP tasks such as setting up and starting
  # the connection, settings status, registering and dispatching filters and handlers and roster management.
  #
  # Client can be used separately from the DSL if you'd like to implement your own DSL
  # Here's the echo example using the client without the DSL:
  #
  #   require 'blather/client/client'
  #   client = Client.setup 'echo@jabber.local', 'echo'
  #
  #   client.register_handler(:ready) { puts "Connected ! send messages to #{client.jid.stripped}." }
  #
  #   client.register_handler :subscription, :request? do |s|
  #     client.write s.approve!
  #   end
  #
  #   client.register_handler :message, :chat?, :body => 'exit' do |m|
  #     client.write Blather::Stanza::Message.new(m.from, 'Exiting...')
  #     client.close
  #   end
  #
  #   client.register_handler :message, :chat?, :body do |m|
  #     client.write Blather::Stanza::Message.new(m.from, "You sent: #{m.body}")
  #   end
  #
  class Client
    attr_reader :jid,
                :roster

    ##
    # Initialize and setup the client
    # * +jid+ - the JID to login with
    # * +password+ - password associated with the JID
    # * +host+ - hostname or IP to connect to. If nil the stream will look one up based on the domain in the JID
    # * +port+ - port to connect to
    def self.setup(jid, password, host = nil, port = nil)
      self.new.setup(jid, password, host, port)
    end

    def initialize # :nodoc:
      @state = :initializing

      @status = Stanza::Presence::Status.new
      @handlers = {}
      @tmp_handlers = {}
      @filters = {:before => [], :after => []}
      @roster = Roster.new self

      setup_initial_handlers
    end

    ##
    # Get the current status. Taken from the +state+ attribute of Status
    def status
      @status.state
    end

    ##
    # Set the status. Status can be set with either a single value or an array containing
    # [state, message, to].
    def status=(state)
      state, msg, to = state

      status = Stanza::Presence::Status.new state, msg
      status.to = to
      @status = status unless to

      write status
    end

    ##
    # Start the connection.
    def run
      raise 'not setup!' unless setup?
      klass = @setup[0].node ? Blather::Stream::Client : Blather::Stream::Component
      @stream = klass.start self, *@setup
    end

    ##
    # Register a filter to be run before or after the handler chain is run.
    # * +type+ - the type of filter. Must be +:before+ or +:after+
    # * +guards+ - guards that should be checked before the filter is called
    def register_filter(type, handler = nil, *guards, &filter)
      raise "Invalid filter: #{type}. Must be :before or :after" unless [:before, :after].include?(type)
      @filters[type] << [guards, handler, filter]
    end

    ##
    # Register a temporary handler. Temporary handlers are based on the ID of the JID and live 
    # only until a stanza with said ID is received. 
    # * +id+ - the ID of the stanza that should be handled
    def register_tmp_handler(id, &handler)
      @tmp_handlers[id] = handler
    end

    ##
    # Register a handler
    # * +type+ - the handler type. Should be registered in Stanza.handler_list. Blather will log a warning if it's not.
    # * +guards+ - the list of guards that must be verified before the handler will be called
    def register_handler(type, *guards, &handler)
      check_handler type, guards
      @handlers[type] ||= []
      @handlers[type] << [guards, handler]
    end

    ##
    # Write data to the stream
    def write(stanza)
      @stream.send(stanza) if @stream
    end

    ##
    # Helper that will create a temporary handler for the stanza being sent before writing it to the stream.
    #
    #   client.write_with_handler(stanza) { |s| "handle stanza here" }
    #
    # is equivalent to:
    #
    #   client.register_tmp_handler(stanza.id) { |s| "handle stanza here" }
    #   client.write stanza
    def write_with_handler(stanza, &handler)
      register_tmp_handler stanza.id, &handler
      write stanza
    end

    ##
    # Close the connection
    def close
      @stream.close_connection_after_writing
    end

    def post_init # :nodoc:
      self.jid.node ? client_post_init : ready!
    end

    def unbind # :nodoc:
      EM.stop if EM.reactor_running?
    end

    def receive_data(stanza) # :nodoc:
      catch(:halt) do
        run_filters :before, stanza
        handle_stanza stanza
        run_filters :after, stanza
      end
    end

    def jid=(new_jid) # :nodoc :
      @jid = JID.new new_jid
    end

    def setup? # :nodoc:
      @setup.is_a? Array
    end

    def setup(jid, password, host = nil, port = nil) # :nodoc:
      @jid = JID.new(jid)
      @setup = [@jid, password]
      @setup << host if host
      @setup << port if port
      self
    end

  protected
    def check_handler(type, guards)
      Blather.logger.warn "Handler for type \"#{type}\" will never be called as it's not a registered type" unless current_handlers.include?(type)
      check_guards guards
    end

    def current_handlers
      [:ready] + Stanza.handler_list + BlatherError.handler_list
    end

    def setup_initial_handlers # :nodoc:
      register_handler :error do |err|
        raise err
      end

      register_handler :iq, :type => [:get, :set] do |iq|
        write StanzaError.new(iq, 'service-unavailable', :cancel).to_node
      end

      register_handler :status do |status|
        roster[status.from].status = status if roster[status.from]
        nil
      end

      register_handler :roster do |node|
        roster.process node
      end
    end

    def ready! # :nodoc:
      @state = :ready
      call_handler_for :ready, nil
    end

    def client_post_init # :nodoc:
      write_with_handler Stanza::Iq::Roster.new do |node|
        roster.process node
        write @status
        ready!
      end
    end

    def run_filters(type, stanza) # :nodoc:
      @filters[type].each do |guards, handler, filter|
        next if handler && !stanza.handler_heirarchy.include?(handler)
        catch(:pass) { call_handler filter, guards, stanza }
      end
    end

    def handle_stanza(stanza) # :nodoc:
      if handler = @tmp_handlers.delete(stanza.id)
        handler.call stanza
      else
        stanza.handler_heirarchy.each do |type|
          break if call_handler_for(type, stanza)
        end
      end
    end

    def call_handler_for(type, stanza) # :nodoc:
      return unless handler = @handlers[type]
      handler.find do |guards, handler|
        catch(:pass) { call_handler handler, guards, stanza }
      end
    end

    def call_handler(handler, guards, stanza) # :nodoc:
      if guards.first.respond_to?(:to_str) && !(result = stanza.find(*guards)).empty?
        handler.call(stanza, result)
      elsif !guarded?(guards, stanza)
        handler.call(stanza)
      end
    end

    ##
    # If any of the guards returns FALSE this returns true
    # the logic is reversed to allow short circuiting
    # (why would anyone want to loop over more values than necessary?)
    def guarded?(guards, stanza) # :nodoc:
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

    def check_guards(guards) # :nodoc:
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
