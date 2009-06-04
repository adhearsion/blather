module Blather # :nodoc:
class Stream # :nodoc:

  class Session < Features # :nodoc:
    SESSION_NS = 'urn:ietf:params:xml:ns:xmpp-session'.freeze
    register SESSION_NS

    def initialize(stream, succeed, fail)
      super
      @to = @stream.jid.domain
    end

    def receive_data(stanza)
      @node = stanza
      case stanza.element_name
      when 'session'  then  session
      when 'iq'       then  check_response
      else                  fail!(UnknownResponse.new(stanza))
      end
    end

  private
    def check_response
      if @node[:type] == 'result'
        succeed!        
      else
        fail!(StanzaError.import(@node))
      end
    end

    ##
    # Send a start session command
    def session
      response = Stanza::Iq.new :set
      response.to = @to
      response << (sess = XMPPNode.new('session', response.document))
      sess.namespace = SESSION_NS

      @stream.send response
    end
  end

end
end
