module Blather
  # Main error class
  class BlatherError < StandardError
    class_inheritable_array :handler_heirarchy
    self.handler_heirarchy ||= []

    @@handler_list = []

    ##
    # Register the class's handler
    def self.register(handler)
      @@handler_list << handler
      self.handler_heirarchy.unshift handler
    end

    ##
    # The list of registered handlers
    def self.handler_list
      @@handler_list
    end

    register :error

    # HACK!! until I can refactor the entire Error object model
    def id # :nodoc:
      nil
    end
  end

  ##
  # Used in cases where a stanza only allows specific values for its attributes
  # and an invalid value is attempted.
  class ArgumentError < BlatherError
    register :argument_error
  end

  ##
  # The stream handler received a response it didn't know how to handle
  class UnknownResponse < BlatherError
    register :unknown_response_error
    attr_reader :node

    def initialize(node)
      @node = node
    end
  end

  ##
  # Something bad happened while parsing the incoming stream
  class ParseError < BlatherError
    register :parse_error
    attr_reader :message

    def initialize(msg)
      @message = msg.to_s
    end
  end
end
