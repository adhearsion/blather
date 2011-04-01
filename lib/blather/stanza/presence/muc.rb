module Blather
class Stanza
class Presence

  class MUC < Presence
    MUC_NS = "http://jabber.org/protocol/muc"

    register :muc_join, :muc_join

    def password
      create_muc.content_from :password
      create_password.content
    end

    def password=(value)
      create_muc.set_content_for :password
    end

    private
      def create_muc
        unless create_muc = find_first('ns:x', :ns => MUC_NS)
           self << (create_muc = XMPPNode.new('x', self.document))
           create_muc.namespace = MUC_NS
         end
         create_muc
      end
  end # MUC

end # Presence
end # Stanza
end # Blather
