require File.join(File.dirname(__FILE__), 'client')

module Blather

  # # Blather DSL
  #
  # The DSL is a set of methods that enables you to write cleaner code. Being a
  # module means it can be included in or extend any class you may want to
  # create.
  #
  # Every stanza handler is registered as a method on the DSL.
  #
  # @example Include the DSL in the top level namespace.
  #
  #     require 'blather/client'
  #     when_ready { puts "Connected ! send messages to #{jid.stripped}." }
  #
  #     subscription :request? do |s|
  #       write_to_stream s.approve!
  #     end
  #
  #     message :chat?, :body => 'exit' do |m|
  #       say m.from, 'Exiting ...'
  #       shutdown
  #     end
  #
  #     message :chat?, :body do |m|
  #       say m.from, "You sent: #{m.body}"
  #     end
  #
  # @example Set the DSL to its own namespace.
  #
  #     require 'blather/client/dsl'
  #     module Echo
  #       extend Blather::DSL
  #       def self.run
  #         client.run
  #       end
  #
  #       when_ready { puts "Connected ! send messages to #{jid.stripped}." }
  #
  #       subscription :request? do |s|
  #         write_to_stream s.approve!
  #       end
  #
  #       message :chat?, :body => 'exit' do |m|
  #         say m.from, 'Exiting ...'
  #         shutdown
  #       end
  #
  #       message :chat?, :body do |m|
  #         say m.from, "You sent: #{m.body}"
  #       end
  #     end
  #
  #     EM.run { Echo.run }
  #
  # @example Create a class out of it
  #
  #     require 'blather/client/dsl'
  #     class Echo
  #       include Blather::DSL
  #     end
  #
  #     echo = Echo.new
  #     echo.when_ready { puts "Connected ! send messages to #{jid.stripped}." }
  #
  #     echo.subscription :request? do |s|
  #       write_to_stream s.approve!
  #     end
  #
  #     echo.message :chat?, :body => 'exit' do |m|
  #       say m.from, 'Exiting ...'
  #       shutdown
  #     end
  #
  #     echo.message :chat?, :body do |m|
  #       say m.from, "You sent: #{m.body}"
  #     end
  #
  #     EM.run { echo.client.run }
  module DSL

    autoload :PubSub, File.expand_path(File.join(File.dirname(__FILE__), *%w[dsl pubsub]))

    def self.append_features(o)
      Blather::Stanza.handler_list.each do |handler_name|
        o.__send__ :remove_method, handler_name if !o.is_a?(Class) && o.method_defined?(handler_name)
      end
      super
    end

    # The actual client connection
    #
    # @return [Blather::Client]
    def client
      @client ||= Client.new
    end
    module_function :client

    # A pubsub helper
    #
    # @return [Blather::PubSub]
    def pubsub
      @pubsub ||= PubSub.new client, jid.domain
    end

    # Push data to the stream
    # This works such that it can be chained:
    #     self << stanza1 << stanza2 << "raw data"
    #
    # @param [#to_xml, #to_s] stanza data to send down the wire
    # @return [self]
    def <<(stanza)
      client.write stanza
      self
    end

    # Prepare server settings
    #
    # @param [#to_s] jid the JID to authenticate with
    # @param [#to_s] password the password to authenticate with
    # @param [String] host (optional) the host to connect to (can be an IP). If
    # this is `nil` the domain on the JID will be used
    # @param [Fixnum, String] (optional) port the port to connect on
    def setup(jid, password, host = nil, port = nil, certs = nil)
      client.setup(jid, password, host, port, certs)
    end

    # Shutdown the connection.
    # Flushes the write buffer then stops EventMachine
    def shutdown
      client.close
    end

    # Setup a before filter
    #
    # @param [Symbol] handler (optional) the stanza handler the filter should
    # run before
    # @param [guards] guards (optional) a set of guards to check the stanza
    # against
    # @yield [Blather::Stanza] stanza
    def before(handler = nil, *guards, &block)
      client.register_filter :before, handler, *guards, &block
    end

    # Setup an after filter
    #
    # @param [Symbol] handler (optional) the stanza handler the filter should
    # run after
    # @param [guards] guards (optional) a set of guards to check the stanza
    # against
    # @yield [Blather::Stanza] stanza
    def after(handler = nil, *guards, &block)
      client.register_filter :after, handler, *guards, &block
    end

    # Set handler for a stanza type
    #
    # @param [Symbol] handler the stanza type it should handle
    # @param [guards] guards (optional) a set of guards to check the stanza
    # against
    # @yield [Blather::Stanza] stanza
    def handle(handler, *guards, &block)
      client.register_handler handler, *guards, &block
    end

    # Wrapper for "handle :ready" (just a bit of syntactic sugar)
    #
    # This is run after the connection has been completely setup
    def when_ready(&block)
      handle :ready, &block
    end

    # Wrapper for "handle :disconnected"
    #
    # This is run after the connection has been shut down.
    #
    # @example Reconnect after a disconnection
    #     disconnected { client.run }
    def disconnected(&block)
      handle :disconnected, &block
    end

    # Set current status
    #
    # @param [Blather::Stanza::Presence::State::VALID_STATES] state the current
    # state
    # @param [#to_s] msg the status message to use
    def set_status(state = nil, msg = nil)
      client.status = state, msg
    end

    # Direct access to the roster
    #
    # @return [Blather::Roster]
    def my_roster
      client.roster
    end

    # Write data to the stream
    #
    # @param [#to_xml, #to_s] stanza the data to send down the wire.
    def write_to_stream(stanza)
      client.write stanza
    end

    # Helper method to make sending basic messages easier
    #
    # @param [Blather::JID, #to_s] to the JID of the message recipient
    # @param [#to_s] msg the message to send
    def say(to, msg)
      client.write Blather::Stanza::Message.new(to, msg)
    end

    # The JID according to the server
    #
    # @return [Blather::JID]
    def jid
      client.jid
    end

    # Halt the handler chain
    #
    # Use this to stop the propogation of the stanza though the handler chain.
    #
    # @example Ignore all IQ stanzas
    #
    #     before(:iq) { halt }
    def halt
      throw :halt
    end

    # Pass responsibility to the next handler
    #
    # Use this to jump out of the current handler and let the next registered
    # handler take care of the stanza
    #
    # @example Pass a message to the next handler
    #
    # This is contrive and should be handled with guards, but pass a message
    # to the next handler based on the content
    #
    #     message { |s| puts "message caught" }
    #     message { |s| pass if s.body =~ /pass along/ }
    def pass
      throw :pass
    end

    # Request items or info from an entity
    #     discover (items|info), [jid], [node] do |response|
    #     end
    def discover(what, who, where, &callback)
      stanza = Blather::Stanza.class_from_registration(:query, "http://jabber.org/protocol/disco##{what}").new
      stanza.to = who
      stanza.node = where

      client.register_tmp_handler stanza.id, &callback
      client.write stanza
    end

    # Set the capabilities of the client
    #
    # @param [String] node the URI
    # @param [Array<Hash>] identities an array of identities
    # @param [Array<Hash>] features an array of features
    def set_caps(node, identities, features)
      client.caps.node = node
      client.caps.identities = identities
      client.caps.features = features
    end

    # Send capabilities to the server
    def send_caps
      client.register_handler :disco_info, :type => :get, :node => client.caps.node do |s|
        r = client.caps.dup
        r.to = s.from
        r.id = s.id
        client.write r
      end
      client.write client.caps.c
    end

    # Generate a method for every stanza handler that exists.
    Blather::Stanza.handler_list.each do |handler_name|
      module_eval <<-METHOD, __FILE__, __LINE__
        def #{handler_name}(*args, &callback)
          handle :#{handler_name}, *args, &callback
        end
      METHOD
    end
  end  # DSL
end  # Blather
