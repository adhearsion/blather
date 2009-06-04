require File.join(File.dirname(__FILE__), 'client')

module Blather
  module DSL

    autoload :PubSub, File.expand_path(File.join(File.dirname(__FILE__), *%w[dsl pubsub]))

    def client
      @client ||= Client.new
    end
    module_function :client

    def pubsub
      @pubsub ||= PubSub.new jid.domain
    end

    ##
    # Push data to the stream
    # This works such that it can be chained:
    #   self << stanza1 << stanza2 << "raw data"
    def <<(stanza)
      write stanza
      self
    end

    ##
    # Prepare server settings
    #   setup [node@domain/resource], [password], [host], [port]
    # host and port are optional defaulting to the domain in the JID and 5222 respectively
    def setup(jid, password, host = nil, port = nil)
      client.setup(jid, password, host, port)
    end

    ##
    # Shutdown the connection.
    # Flushes the write buffer then stops EventMachine
    def shutdown
      client.close
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
    def set_status(state = nil, msg = nil)
      client.status = state, msg
    end

    ##
    # Direct access to the roster
    def my_roster
      client.roster
    end

    ##
    # Write data to the stream
    # Anything that resonds to #to_s can be paseed to the stream
    def write(stanza)
      client.write stanza
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
    # Request items or info from an entity
    #   discover (items|info), [jid], [node] do |response|
    #   end
    def discover(what, who, where, &callback)
      stanza = Blather::Stanza.class_from_registration(:query, "http://jabber.org/protocol/disco##{what}").new
      stanza.to = who
      stanza.node = where

      client.temporary_handler stanza.id, &callback
      write stanza
    end

    ##
    # Checks to see if the method is part of the handlers list.
    # If so it creates a handler, otherwise it'll pass it back
    # to Ruby's method_missing handler
    Blather::Stanza.handler_list.each do |handler_name|
      module_eval <<-METHOD, __FILE__, __LINE__
        def #{handler_name}(*args, &callback)
          handle :#{handler_name}, *args, &callback
        end
      METHOD
    end
  end #DSL
end #Blather
