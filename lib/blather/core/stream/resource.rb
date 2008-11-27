module Blather
module Stream

  class Resource
    def initialize(stream, jid)
      @stream = stream
      @jid = jid
      @callbacks = {}
    end

    def success(&callback)
      @callbacks[:success] = callback
    end

    def failure(&callback)
      @callbacks[:failure] = callback
    end

    def receive(node)
      @node = node
      __send__(@node.element_name == 'iq' ? @node['type'] : @node.element_name)
    end

    def bind
      binder = XMPPNode.new('bind')
      binder.xmlns = 'urn:ietf:params:xml:ns:xmpp-bind'

      binder << XMPPNode.new('resource', @jid.resource) if @jid.resource

      response = Stanza::Iq.new :set
      @id = response.id
      response << binder

      @stream.send response
    end

    def result
      LOG.debug "RESOURE NODE #{@node}"
      if @id == @node['id']
        @jid = JID.new @node.find_first('bind').content_from(:jid)
        @callbacks[:success].call(@jid) if @callbacks[:success]
      end
    end

    def error
      @callbacks[:failure].call if @callbacks[:failure]
    end
  end #Resource

end #Stream
end #Blather
