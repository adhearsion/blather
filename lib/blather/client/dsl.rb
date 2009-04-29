require File.join(File.dirname(__FILE__), 'client')

module Blather
  module DSL
    def client
      @client ||= Client.new
    end
    module_function :client

    ##
    # Prepare server settings
    #   setup [node@domain/resource], [password], [host], [port]
    # host and port are optional defaulting to the domain in the JID and 5222 respectively
    def setup(jid, password, host = nil, port = nil)
      client.setup(jid, password, host, port)
      at_exit { client.run }
    end

    ##
    # Shutdown the connection.
    # Flushes the write buffer then stops EventMachine
    def shutdown
      client.stop
    end

    ##
    # Set handler for a stanza type
    def handle(stanza_type, *guards, &block)
      client.register_handler stanza_type, *guards, &block
    end

    ##
    # Wrapper for "handle :ready" (just a bit of syntactic sugar)
    def when_ready(&block)
      handle :ready, &block
    end

    ##
    # Set current status
    def status(state = nil, msg = nil)
      client.status = state, msg
    end

    ##
    # Direct access to the roster
    def roster
      client.roster
    end

    ##
    # Write data to the stream
    # Anything that resonds to #to_s can be paseed to the stream
    def write(stanza)
      client.write(stanza)
    end

    ##
    # Helper method to make sending basic messages easier
    #   say [jid], [msg]
    def say(to, msg)
      client.write Blather::Stanza::Message.new(to, msg)
    end

    ##
    # Wrapper to grab the current JID
    def jid
      client.jid
    end

    ##
    #
    def discover(what, who, where, &callback)
      stanza = Blather::Stanza.class_from_registration(:query, "http://jabber.org/protocol/disco##{what}").new
      stanza.to = who
      stanza.node = where

      client.temporary_handler stanza.id, &callback
      write stanza
    end

    ##
    # PubSub proxy
    def pubsub
      client.pubsub
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
  end #DSL
end #Blather
