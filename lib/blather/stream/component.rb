module Blather
class Stream

  # @private
  class Component < Stream
    NAMESPACE = 'jabber:component:accept'

    def receive(node) # :nodoc:
      if node.node_name == 'handshake'
        ready!
      else
        super
      end

      if node.document.at_xpath('/stream:stream[not(stream:error)]', :xmlns => NAMESPACE, :stream => STREAM_NS)
        send "<handshake>#{Digest::SHA1.hexdigest(node['id']+@password)}</handshake>"
      end
    end

    def send(stanza)
      stanza.from ||= self.jid if stanza.respond_to?(:from) && stanza.respond_to?(:from=)
      super stanza
    end

    def start
      @parser = Parser.new self
      send "<stream:stream to='#{@jid}' xmlns='#{NAMESPACE}' xmlns:stream='#{STREAM_NS}'>"
    end

    def cleanup
      @parser.finish if @parser
      super
    end
  end #Client

end #Stream
end #Blather
