module Blather # :nodoc:
class Stream # :nodoc:

  class TLS < Features # :nodoc:
    class TLSFailure < BlatherError
      register :tls_failure
    end

    TLS_NS = 'urn:ietf:params:xml:ns:xmpp-tls'.freeze
    register TLS_NS

    def receive_data(stanza)
      case stanza.element_name
      when 'starttls'
        @stream.send "<starttls xmlns='#{TLS_NS}'/>"
      when 'proceed'
        @stream.start_tls
        @stream.start
        succeed!
      else
        fail! TLSFailure.new
      end
    end

  end #TLS

end #Stream
end #Blather
