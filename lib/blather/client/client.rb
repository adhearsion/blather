require File.join(File.dirname(__FILE__), *%w[.. .. blather])

module Blather
  # # Blather Client
  #
  # Blather's Client class provides a set of helpers for working with common
  # XMPP tasks such as setting up and starting the connection, settings
  # status, registering and dispatching filters and handlers and roster
  # management.
  #
  # Client can be used separately from the DSL if you'd like to implement your
  # own DSL Here's the echo example using the client without the DSL:
  #
  #     require 'blather/client/client'
  #     client = Client.setup 'echo@jabber.local', 'echo'
  #
  #     client.register_handler(:ready) do
  #       puts "Connected ! send messages to #{client.jid.stripped}."
  #     end
  #
  #     client.register_handler :subscription, :request? do |s|
  #       client.write s.approve!
  #     end
  #
  #     client.register_handler :message, :chat?, :body => 'exit' do |m|
  #       client.write Blather::Stanza::Message.new(m.from, 'Exiting...')
  #       client.close
  #     end
  #
  #     client.register_handler :message, :chat?, :body do |m|
  #       client.write Blather::Stanza::Message.new(m.from, "You sent: #{m.body}")
  #     end
  #
  class Client
    attr_reader :jid,
                :roster,
                :caps,
                :queue_size

    # Create a new client and set it up
    #
    # @param [Blather::JID, #to_s] jid the JID to authorize with
    # @param [String] password the password to authorize with
    # @param [String] host if this isn't set it'll be resolved off the JID's
    # domain
    # @param [Fixnum, String] port the port to connect to.
    # @param [Hash] options a list of options to create the client with
    # @option options [Number] :workqueue_count (5) the number of threads used to process incoming XMPP messages.
    #   If this parameter is specified with 0, no background threads are used;
    #   instead stanzas are handled in the same process that the Client is running in.
    #
    # @return [Blather::Client]
    def self.setup(jid, password, host = nil, port = nil, certs = nil, connect_timeout = nil, options = {})
      self.new.setup(jid, password, host, port, certs, connect_timeout, options)
    end


    def initialize  # @private
      @state = :initializing

      @status = Stanza::Presence::Status.new
      @handlers = {}
      @tmp_handlers = {}
      @filters = {:before => [], :after => []}
      @roster = Roster.new self
      @caps = Stanza::Capabilities.new
      @queue_size = 5

      setup_initial_handlers
    end

    # Check whether the client is currently connected.
    def connected?
      setup? && !@stream.nil? && !@stream.stopped?
    end

    # Get the current status. Taken from the `state` attribute of Status
    def status
      @status.state
    end

    # Set the status. Status can be set with either a single value or an array
    # containing
    #
    # [state, message, to].
    def status=(state)
      state, msg, to = state

      status = Stanza::Presence::Status.new state, msg
      status.to = to
      @status = status unless to

      write status
    end

    # Start the connection.
    #
    # The stream type used is based on the JID. If a node exists it uses
    # Blather::Stream::Client otherwise Blather::Stream::Component
    def run
      raise 'not setup!' unless setup?
      klass = @setup[0].node ? Blather::Stream::Client : Blather::Stream::Component
      klass.start self, *@setup
    end
    alias_method :connect, :run

    # Register a filter to be run before or after the handler chain is run.
    #
    # @param [<:before, :after>] type the filter type
    # @param [Symbol, nil] handler set the filter on a specific handler
    # @param [guards] guards take a look at the guards documentation
    # @yield [Blather::Stanza] stanza the incomming stanza
    def register_filter(type, handler = nil, *guards, &filter)
      unless [:before, :after].include?(type)
        raise "Invalid filter: #{type}. Must be :before or :after"
      end
      @filters[type] << [guards, handler, filter]
    end

    # Register a temporary handler. Temporary handlers are based on the ID of
    # the JID and live only until a stanza with said ID is received.
    #
    # @param [#to_s] id the ID of the stanza that should be handled
    # @yield [Blather::Stanza] stanza the incomming stanza
    def register_tmp_handler(id, &handler)
      @tmp_handlers[id.to_s] = handler
    end

    # Clear handlers with given guards
    #
    # @param [Symbol, nil] type remove filters for a specific handler
    # @param [guards] guards take a look at the guards documentation
    def clear_handlers(type, *guards)
      @handlers[type].delete_if { |g, _| g == guards }
    end

    # Register a handler
    #
    # @param [Symbol, nil] type set the filter on a specific handler
    # @param [guards] guards take a look at the guards documentation
    # @yield [Blather::Stanza] stanza the incomming stanza
    def register_handler(type, *guards, &handler)
      check_handler type, guards
      @handlers[type] ||= []
      @handlers[type] << [guards, handler]
    end

    # Write data to the stream
    #
    # @param [#to_xml, #to_s] stanza the content to send down the wire
    def write(stanza)
      self.stream.send(stanza)
    end

    # Helper that will create a temporary handler for the stanza being sent
    # before writing it to the stream.
    #
    #     client.write_with_handler(stanza) { |s| "handle stanza here" }
    #
    # is equivalent to:
    #
    #     client.register_tmp_handler(stanza.id) { |s| "handle stanza here" }
    #     client.write stanza
    #
    # @param [Blather::Stanza] stanza the stanza to send down the wire
    # @yield [Blather::Stanza] stanza the reply stanza
    def write_with_handler(stanza, &handler)
      register_tmp_handler stanza.id, &handler
      write stanza
    end

    # Close the connection
    def close
      EM.next_tick { self.stream.close_connection_after_writing }
    end

    # @private
    def post_init(stream, jid = nil)
      @stream = stream
      @jid = JID.new(jid) if jid
      self.jid.node ? client_post_init : ready!
    end

    # @private
    def unbind
      call_handler_for(:disconnected, nil) || (EM.reactor_running? && EM.stop)
    end

    # @private
    def receive_data(stanza)
      if handler_queue
        handler_queue << stanza
      else
        handle_data stanza
      end
    end

    def handle_data(stanza)
      catch(:halt) do
        run_filters :before, stanza
        handle_stanza stanza
        run_filters :after, stanza
      end
    end

    # @private
    def setup?
      @setup.is_a? Array
    end

    # @private
    def setup(jid, password, host = nil, port = nil, certs = nil, connect_timeout = nil, options = {})
      @jid = JID.new(jid)
      @setup = [@jid, password]
      @setup << host
      @setup << port
      @setup << certs
      @setup << connect_timeout
      @queue_size = options[:workqueue_count] || 5
      self
    end

    # @private
    def handler_queue
      return if queue_size == 0
      @handler_queue ||= GirlFriday::WorkQueue.new :handle_stanza, :size => queue_size do |stanza|
        handle_data stanza
      end
    end

    protected

    def stream
      @stream || raise('Stream not ready!')
    end

    def check_handler(type, guards)
      Blather.logger.warn "Handler for type \"#{type}\" will never be called as it's not a registered type" unless current_handlers.include?(type)
      check_guards guards
    end

    def current_handlers
      [:ready, :disconnected] + Stanza.handler_list + BlatherError.handler_list
    end

    def setup_initial_handlers
      register_handler :error do |err|
        raise err
      end

      # register_handler :iq, :type => [:get, :set] do |iq|
      #   write StanzaError.new(iq, 'service-unavailable', :cancel).to_node
      # end

      register_handler :ping, :type => :get do |ping|
        write ping.reply
      end

      register_handler :status do |status|
        roster[status.from].status = status if roster[status.from]
        nil
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

    def run_filters(type, stanza)
      @filters[type].each do |guards, handler, filter|
        next if handler && !stanza.handler_hierarchy.include?(handler)
        catch(:pass) { call_handler filter, guards, stanza }
      end
    end

    def handle_stanza(stanza)
      if handler = @tmp_handlers.delete(stanza.id)
        handler.call stanza
      else
        stanza.handler_hierarchy.each do |type|
          break if call_handler_for(type, stanza)
        end
      end
    end

    def call_handler_for(type, stanza)
      return unless handler = @handlers[type]
      handler.find do |guards, handler|
        catch(:pass) { call_handler handler, guards, stanza }
      end
    end

    def call_handler(handler, guards, stanza)
      if guards.first.respond_to?(:to_str)
        result = stanza.find(*guards)
        handler.call(stanza, result) unless result.empty?
      else
        handler.call(stanza) unless guarded?(guards, stanza)
      end
    end

    # If any of the guards returns FALSE this returns true
    # the logic is reversed to allow short circuiting
    # (why would anyone want to loop over more values than necessary?)
    #
    # @private
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
            # last_match is the only method found unique to Regexp classes
            if test.class.respond_to?(:last_match)
              !(test =~ value.to_s)
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
  end  # Client

end  # Blather
