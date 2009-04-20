module Blather # :nodoc:
class Stream # :nodoc:

  class StreamHandler # :nodoc:
    def on_success(&block); @success = block; end
    def on_failure(&block); @failure = block; end

    def initialize(stream)
      @stream = stream
    end

    def handle(node)
      @node = node
      method = @node.element_name == 'iq' ? @node['type'] : @node.element_name
      if self.respond_to?(method, true)
        self.__send__ method
      else
        @failure.call UnknownResponse.new(@node)
      end
    end

  protected
    ##
    # Handle error response from the server
    def error
      failure
    end

    def success(message_back = nil)
      @success.call message_back
    end

    def failure(err = nil)
      @failure.call err
    end
  end #StreamHandler

end #Stream
end #Blather