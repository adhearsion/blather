module Blather # :nodoc:
class Stream # :nodoc:

  class Resource < StreamHandler # :nodoc:
    BIND_NS = 'urn:ietf:params:xml:ns:xmpp-bind'

    def initialize(stream, jid)
      super stream
      @jid = jid
    end

  private
    ##
    # Respond to the bind request
    # If @jid has a resource set already request it from the server
    def bind
      response = Stanza::Iq.new :set
      @id = response.id

      response << (binder = XMPPNode.new('bind'))
      binder.namespace = BIND_NS

      if @jid.resource
        binder << (resource = XMPPNode.new('resource'))
        resource.content = @jid.resource
      end

      @stream.send response
    end

    ##
    # Process the result from the server
    # Sets the sends the JID (now bound to a resource)
    # back to the stream
    def result
      Blather.logger.debug "RESOURCE NODE #{@node}"
      # ensure this is a response to our original request
      if @id == @node['id']
        @jid = JID.new @node.find_first('//bind_ns:bind/bind_ns:jid', :bind_ns => BIND_NS).content
        success @jid
      end
    end

    ##
    # Server returned an error
    def error
      failure StanzaError.import(@node)
    end
  end #Resource

end #Stream
end #Blather
