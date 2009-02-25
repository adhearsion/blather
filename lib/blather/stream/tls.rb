module Blather # :nodoc:
module Stream # :nodoc:

  class TLS # :nodoc:
    def on_success(&block); @success = block; end
    def on_failure(&block); @failure = block; end

    def initialize(stream)
      @stream = stream
    end

    ##
    # Handle the incoming node.
    #
    # TLS negotiation invovles 3 node types:
    #   * starttls  -- Server asking for TLS to be started
    #   * proceed   -- Server saying it's ready for a TLS connection to be started
    #   * failure   -- Failed TLS negotiation. Failure results in a closed connection.
    #                  so there's no message to pass back to the tream
    def handle(node)
      if self.respond_to?(node.element_name, true)
        self.__send__(node.element_name)
      else
        failure
      end
    end

  private
    def starttls
      @stream.send "<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>"
    end

    def proceed
      @stream.start_tls
      @success.call
    end

    def failure
      @failure.call
    end
  end #TLS

end #Stream
end #Blather