module Blather # :nodoc:
module Stream # :nodoc:

  class Resource # :nodoc:
    def on_success(&block); @success = block; end
    def on_failure(&block); @failure = block; end

    def initialize(stream, jid)
      @stream = stream
      @jid = jid
    end

    def handle(node)
      @node = node
      method = @node.element_name == 'iq' ? @node['type'] : @node.element_name
      if self.respond_to?(method, true)
        self.__send__(method)
      else
        failure
      end
    end

  private
    def success(jid)
      @success.call jid
    end

    def failure
      @failure.call
    end

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
        @jid = JID.new @node.find_first('bind/jid').content
        success @jid
      end
    end

    ##
    # Handle error response from the server
    def error
      failure
    end
  end #Resource

end #Stream
end #Blather
