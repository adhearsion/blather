module Blather
  # Main error class
  class BlatherError < StandardError
    class_inheritable_array :handler_heirarchy

    self.handler_heirarchy ||= []
    self.handler_heirarchy << :error

    def self.register(handler)
      self.handler_heirarchy.unshift handler
    end
  end

  ##
  # Used in cases where a stanza only allows specific values for its attributes
  # and an invalid value is attempted.
  class ArgumentError < BlatherError
    register :argument_error
  end
end
