module Blather # :nodoc:
class Stream # :nodoc:

  # TLS negotiation invovles 3 node types:
  #   * starttls  -- Server asking for TLS to be started
  #   * proceed   -- Server saying it's ready for a TLS connection to be started
  #   * failure   -- Failed TLS negotiation. Failure results in a closed connection.
  #                  so there's no message to pass back to the tream
  class TLS < StreamHandler # :nodoc:
  private
    ##
    # After receiving <starttls> from the server send one
    # back to let it know we're ready to start TLS
    def starttls
      @stream.send "<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>"
    end

    ##
    # Server's ready for TLS, so start it up
    def proceed
      @stream.start_tls
      success
    end

    ##
    # Negotiations failed
    def failure
      super StreamError::TLSFailure.new
    end
  end #TLS

end #Stream
end #Blather