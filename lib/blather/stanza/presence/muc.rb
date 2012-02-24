module Blather
class Stanza
class Presence

  class MUC < Status
    register :muc_join, :x, "http://jabber.org/protocol/muc"

    private
      def muc
        unless muc = find_first('ns:x', :ns => self.class.registered_ns)
          self << (muc = XMPPNode.new('x', self.document))
        end
        muc
      end
  end # MUC

end # Presence
end # Stanza
end # Blather
