module Blather
class Stream

  class Component < Stream
    NAMESPACE = 'jabber:component:accept'

    def receive(node) # :nodoc:
      if node.element_name == 'handshake'
        @client.post_init
      else
        super
      end

      if node.namespaces.find_by_href('http://etherx.jabber.org/streams') && node.find_first('/stream:stream[not(stream:error)]')
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
