module Blather # :nodoc:
module Stream # :nodoc:

  class Session # :nodoc:
    def on_success(&block); @success = block; end
    def on_failure(&block); @failure = block; end

    def initialize(stream, to)
      @stream = stream
      @to = to
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
    def session
      response = Stanza::Iq.new :set
      response.to = @to
      sess = XMPPNode.new 'session'
      sess['xmlns'] = 'urn:ietf:params:xml:ns:xmpp-session'
      response << sess
      @stream.send response
    end

    def result
      success
    end

    def error
      failure
    end

    def success
      @success.call
    end

    def failure
      @failure.call
    end
  end

end
end
