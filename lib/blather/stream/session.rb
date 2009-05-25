module Blather # :nodoc:
class Stream # :nodoc:

  class Session < StreamHandler # :nodoc:
    SESSION_NS = 'urn:ietf:params:xml:ns:xmpp-session'

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
      response << (sess = XMPPNode.new('session', response.document))
      sess.namespace = SESSION_NS

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
