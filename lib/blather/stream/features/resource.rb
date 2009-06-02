module Blather # :nodoc:
class Stream # :nodoc:

  class Resource < Features # :nodoc:
    BIND_NS = 'urn:ietf:params:xml:ns:xmpp-bind'.freeze
    register BIND_NS

    def initialize(stream, succeed, fail)
      super
      @jid = stream.jid
    end

    def receive_data(stanza)
      @node = stanza
      case stanza.element_name
      when 'bind' then  bind
      when 'iq'   then  result
      else              fail!(UnknownResponse.new(@node))
      end
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
      if @node[:type] == 'error'
        fail! StanzaError.import(@node)
        return
      end

      Blather.logger.debug "RESOURCE NODE #{@node}"
      # ensure this is a response to our original request
      if @id == @node['id']
        @stream.jid = JID.new @node.find_first('//bind/bind_ns:jid', :bind_ns => BIND_NS).content
        succeed!
      else
        fail!("BIND result ID mismatch. Expected: #{@id}. Received: #{@node['id']}")
      end
    end
  end #Resource

end #Stream
end #Blather
