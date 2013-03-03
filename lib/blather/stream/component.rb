module Blather
class Stream

  # @private
  class Component < Stream
    NAMESPACE = 'jabber:component:accept'

    def receive(node) # :nodoc:
      if node.element_name == 'handshake'
        ready!
      else
        super
      end

      if node.document.find_first('/stream:stream[not(stream:error)]', :xmlns => NAMESPACE, :stream => STREAM_NS)
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
  end #Client

end #Stream
end #Blather
