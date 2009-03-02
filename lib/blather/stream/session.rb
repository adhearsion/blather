module Blather # :nodoc:
module Stream # :nodoc:

  class Session < StreamHandler # :nodoc:
    def initialize(stream, to)
      super stream
      @to = to
    end

  private
    ##
    # Send a start session command
    def session
      response = Stanza::Iq.new :set
      response.to = @to
      sess = XMPPNode.new 'session'
      sess['xmlns'] = 'urn:ietf:params:xml:ns:xmpp-session'
      response << sess
      @stream.send response
    end

    ##
    # The server should respond with a <result> node if all is well
    def result
      success
    end

    ##
    # Server returned an error.
    def error
      failure StanzaError.import(@node)
    end
  end

end
end
