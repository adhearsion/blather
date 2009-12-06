module Blather
  # Main error class
  # This starts the error hierarchy
  #
  # @handler :error
  class BlatherError < StandardError
    class_inheritable_array :handler_hierarchy
    self.handler_hierarchy ||= []

    # @private
    @@handler_list = []

    # Register the class's handler
    #
    # @param [Symbol] handler the handler name
    def self.register(handler)
      @@handler_list << handler
      self.handler_hierarchy.unshift handler
    end

    # The list of registered handlers
    #
    # @return [Array<Symbol>] a list of currently registered handlers
    def self.handler_list
      @@handler_list
    end

    register :error

    # @private
    # HACK!! until I can refactor the entire Error object model
    def id
      nil
    end
  end  # BlatherError

  # Used in cases where a stanza only allows specific values for its attributes
  # and an invalid value is attempted.
  #
  # @handler :argument_error
  class ArgumentError < BlatherError
    register :argument_error
  end  # ArgumentError

  # The stream handler received a response it didn't know how to handle
  #
  # @handler :unknown_response_error
  class UnknownResponse < BlatherError
    register :unknown_response_error
    attr_reader :node

    def initialize(node)
      @node = node
    end
  end  # UnknownResponse

  # Something bad happened while parsing the incoming stream
  #
  # @handler :parse_error
  class ParseError < BlatherError
    register :parse_error
    attr_reader :message

    def initialize(msg)
      @message = msg.to_s
    end
  end  # ParseError

end  # Blather
