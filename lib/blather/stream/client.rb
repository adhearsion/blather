module Blather
class Stream

  # @private
  class Client < Stream
    LANG = 'en'
    VERSION = '1.0'
    NAMESPACE = 'jabber:client'

    def start
      @parser = Parser.new self
      send "<stream:stream to='#{@to}' xmlns='#{NAMESPACE}' xmlns:stream='#{STREAM_NS}' version='#{VERSION}' xml:lang='#{LANG}'>"
    end

    def send(stanza)
      stanza.from = self.jid if stanza.is_a?(Stanza) && !stanza.from.nil?
      super stanza
    end

  end #Client

end #Stream
end #Blather
