module Blather
module DSL
  # TODO
  #  Get room name?

  class MUC
    def initialize(client, jid, nickname = nil, password = nil)
      @client   = client
      @room     = JID.new(jid)
      @nickname = nickname || @room.resource
      @password = password
      @room.strip!
    end
    
    def join(reason = nil)
      status       = Stanza::Presence::Status.new
      status.to    = "#{@room}/#{@nickname}"
      status       << Stanza::MUC::Join.new(@password)
      write status
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
    def say(msg, xhtml = nil)
      message = Stanza::Message.new(@room, msg, :groupchat)
      message.xhtml = xhtml if xhtml
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
    
    # <iq from='crone1@shakespeare.lit/desktop'
    #     id='begone'
    #     to='heath@chat.shakespeare.lit'
    #     type='set'>
    #   <query xmlns='http://jabber.org/protocol/muc#owner'>
    #     <destroy jid='darkcave@chat.shakespeare.lit'>
    #       <reason>Macbeth doth come.</reason>
    #     </destroy>
    #   </query>
    # </iq>
    def destroy(reason = nil)
      destroy = Blather::Stanza::Iq::MUC::Owner::Destroy.new(@room)
      destroy.reason = reason
      write destroy
    end
    
    def get_configuration(&block)
      get_configure = Blather::Stanza::Iq::MUC::Owner::Configure.new(:get, @room)
      write_with_handler(get_configure) do |stana|
        yield stana
      end
    end
    alias_method :configuration, :get_configuration
    
    def set_configuration(values, &block)
      set_configure = Blather::Stanza::Iq::MUC::Owner::Configure.new(:set, @room)
      set_configure.data = values
      write_with_handler(set_configure, &block)
    end
    alias_method :configuration=, :set_configuration
    
    #  <iq type='set' id='purple52b37aa2' to='test3@conference.macbook.local'>
    #   <query xmlns='http://jabber.org/protocol/muc#owner'>
    #   <x xmlns='jabber:x:data' type='submit'/></query>
    # </iq>
    def set_default_configuration(&block)
      set_configuration(:default) do
        yield if block_given?
      end
    end
    alias_method :unlock, :set_default_configuration
    
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
    def members(&block)
      members = Blather::Stanza::Iq::MUC::Admin::Members.new(@room)
      write_with_handler(members, &block)
    end
    
    def write(stanza)
      @client.write(stanza)
    end
    
    def write_with_handler(stanza, &block)
      @client.write_with_handler(stanza, &block)
    end
  end
  
end # Blather
end # DSL