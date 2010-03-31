module Blather
class Stanza
module MUC
  
# <message to='room@service'>
#   <x xmlns='http://jabber.org/protocol/muc#user'>
#     <invite to='jid'>
#       <reason>comment</reason>
#     </invite>
#   </x>
# </message>  
class Invite < XMPPNode
  register :x, "http://jabber.org/protocol/muc#user"
  
  def self.new(jid, comment = nil)
    # invite = super :x
    # invite.to = jid
    # JID.new(jid)
  end
end

end
end
end