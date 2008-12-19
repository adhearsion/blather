module Blather # :nodoc:
module Stream # :nodoc:

  class Session # :nodoc:
    def initialize(stream, to)
      @stream = stream
      @to = to
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

    def session
      response = Stanza::Iq.new :set
      response.to = @to
      sess = XMPPNode.new 'session'
      sess['xmlns'] = 'urn:ietf:params:xml:ns:xmpp-session'
      response << sess
      @stream.send response
    end

    def result
      @callbacks[:success].call(@jid) if @callbacks[:success]
    end

    def error
      @callbacks[:failure].call if @callbacks[:failure]
    end
  end

end
end
