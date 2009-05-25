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

      if node.document.find_first('/stream:stream[not(stream:error)]', :xmlns => NAMESPACE, :stream => STREAM_NS)
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
          xmlns:stream='#{STREAM_NS}'
        >
      STREAM
      send start_stream.gsub(/\s+/, ' ')
    end
  end #Client

end #Stream
end #Blather
