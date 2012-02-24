module Blather
class Stanza
class Presence

  class MUCUser < Status
    register :muc_user, :x, "http://jabber.org/protocol/muc#user"

    def affiliation
      item[:affiliation]
    end

    def affiliation=(val)
      item[:affiliation] = val
    end

    def role
      item[:role]
    end

    def role=(val)
      item[:role] = val
    end

    def jid
      item[:jid]
    end

    def jid=(val)
      item[:jid] = val
    end

    def status_code
      status[:code]
    end

    def status_code=(val)
      status[:code] = val
    end

    private
      def muc_user
        unless muc_user = find_first('ns:x', :ns => self.class.registered_ns)
          self << (muc_user = XMPPNode.new('x', self.document))
        end
        muc_user
      end

      def item
        unless item = muc_user.find_first('ns:item', :ns => self.class.registered_ns)
          muc_user << (item = XMPPNode.new('item', self.document))
        end
        item
      end

      def status
        unless status = muc_user.find_first('ns:status', :ns => self.class.registered_ns)
          muc_user << (status = XMPPNode.new('status', self.document))
        end
        status
      end
  end # MUC

end # Presence
end # Stanza
end # Blather
