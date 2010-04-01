module Blather
module DSL
  # TODO
  #  Get room name?
  #  Room configuration

  class MUC
    def initialize(client, jid, password = nil)
      @client   = client
      @room     = JID.new(jid)
      @password = password
    end
    
    def join
      status       = Stanza::Presence::Status.new
      status.to    = @room
      status       << Stanza::MUC::Join.new(@password)
      write status
    end
    
    # <presence
    #     from='wiccarocks@shakespeare.lit/laptop'
    #     to='darkcave@chat.shakespeare.lit/oldhag'>
    #     <x xmlns='http://jabber.org/protocol/muc'>
    #       <password>pass</password>
    #     </x>
    #   <show>available</show>
    # </presence>
    def status=(state)
      status       = Stanza::Presence::Status.new
      status.state = state
      status.to    = @room
      status       << Stanza::MUC::Invite.new(@password)
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
      message = Stanza::Message.new(@room, nil, nil)
      message << Stanza::MUC::Invite.new(jid, reason, @password)
      write message
    end

    # <message to='room@service' type='groupchat'>
    #   <body>foo</body>
    # </message>    
    def say(msg)
      message = Stanza::Message.new(@room, msg, :groupchat)
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
    
    #  <iq type='set' id='purple52b37aa2' to='test3@conference.macbook.local'>
    #   <query xmlns='http://jabber.org/protocol/muc#owner'>
    #   <x xmlns='jabber:x:data' type='submit'/></query>
    # </iq>
    def unlock
      write Blather::Stanza::Iq::MUC::Owner.new(:set, @room, "submit")
    end
    
    # <iq from='crone1@shakespeare.lit/desktop'
    #     id='member3'
    #     to='darkcave@chat.shakespeare.lit'
    #     type='get'>
    #   <query xmlns='http://jabber.org/protocol/muc#admin'>
    #     <item affiliation='member'/>
    #   </query>
    # </iq>
    # 
    # <iq from='darkcave@chat.shakespeare.lit'
    #     id='member3'
    #     to='crone1@shakespeare.lit/desktop'
    #     type='result'>
    #   <query xmlns='http://jabber.org/protocol/muc#admin'>
    #     <item affiliation='member'
    #           jid='hag66@shakespeare.lit'
    #           nick='thirdwitch'
    #           role='participant'/>
    #   </query>
    # </iq>
    def members
      
    end
    
    def write(stanza)
      @client.write(stanza)
    end
  end
  
end # Blather
end # DSL