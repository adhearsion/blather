module Blather # :nodoc:
class Stream # :nodoc:

  class Resource < StreamHandler # :nodoc:
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

      binder = XMPPNode.new('bind')
      binder.namespace = 'urn:ietf:params:xml:ns:xmpp-bind'

      binder << XMPPNode.new('resource', @jid.resource) if @jid.resource

      response << binder
      @stream.send response
    end

    ##
    # Process the result from the server
    # Sets the sends the JID (now bound to a resource)
    # back to the stream
    def result
      LOG.debug "RESOURE NODE #{@node}"
      # ensure this is a response to our original request
      if @id == @node['id']
        @jid = JID.new @node.find_first('//bind_ns:bind/jid', :bind_ns => 'urn:ietf:params:xml:ns:xmpp-bind').content
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
