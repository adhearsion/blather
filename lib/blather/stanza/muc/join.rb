module Blather
class Stanza
module MUC
  
class Join < XMPPNode
  register :x, "http://jabber.org/protocol/muc"
  
  def self.new(password = nil)
    join = super :x
    join.password = password
    join
  end
  
  def password=(password)
    return if password.blank?
    create_password.content = password
  end
  
  protected
    def create_password
     unless create_password = find_first('ns:password', :ns => self.class.registered_ns)
        self << (create_password = XMPPNode.new('password', self.document))
      end
      create_password
    end
end

end
end
end