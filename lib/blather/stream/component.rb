module Blather
class Stream

  class Component < Stream
    NAMESPACE = 'jabber:component:accept'

    def self.start(client, host, port, jid, secret)
      jid = JID.new jid
      host ||= jid.domain

      EM.connect host, port, self, client, jid, secret
    end

    def receive(node) # :nodoc:
      if node.element_name == 'handshake'
        @client.stream_started(self)
      else
        super
      end

      if node.element_name == 'stream:stream'
        send("<handshake>#{Digest::SHA1.hexdigest(@node['id']+@pass)}</handshake>")
      end
    end

  protected
    def start
      @parser = Parser.new self
      start_stream = <<-STREAM
        <stream:stream
          to='#{@jid}'
          xmlns='#{NAMESPACE}'
          xmlns:stream='http://etherx.jabber.org/streams'
        >
      STREAM
      send start_stream.gsub(/\s+/, ' ')
    end
  end #Client

end #Stream
end #Blather
