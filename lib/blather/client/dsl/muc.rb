module Blather
module DSL

  class MUC
    def initialize(client, jid)
      @client = client
      @room   = JID.new(jid)
    end
    
    # <presence
    #     from='crone1@shakespeare.lit/desktop'
    #     to='darkcave@chat.shakespeare.lit/firstwitch'>
    #   <x xmlns='http://jabber.org/protocol/muc'/>
    # </presence>
    def join
      self.status = :available
    end
    
    # <presence
    #     from='wiccarocks@shakespeare.lit/laptop'
    #     to='darkcave@chat.shakespeare.lit/oldhag'>
    #   <show>available</show>
    # </presence>
    def status=(state)
      status       = Stanza::Presence::Status.new
      status.state = state
      status.to    = @room
      # add muc stanza
      write status
    end
    
    # <message to='room@service'>
    #   <x xmlns='http://jabber.org/protocol/muc#user'>
    #     <invite to='jid'>
    #       <reason>comment</reason>
    #     </invite>
    #   </x>
    # </message>
    def invite(jid, reason = nil)
      
    end

    # <message to='room@service' type='groupchat'>
    #   <body>foo</body>
    # </message>    
    def say(msg)
      message = Blather::Stanza::Message.new(@room, msg, :groupchat)
      write message
    end
    
    # <message to='room@service' type='groupchat'>
    #   <subject>foo</subject>
    # </message>    
    def subject=(body)
      message = Blather::Stanza::Message.new(@room, nil, :groupchat)
      message.subject = body
      write message
    end
    
    def leave
      self.status = :unavailable
    end
    
    def write(stanza)
      @client.write(stanza)
    end
  end
  
end # Blather
end # DSL