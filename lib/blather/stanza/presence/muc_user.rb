module Blather
class Stanza
class Presence

  class MUCUser < Presence
    class Status < XMPPNode
      def self.new(code)
        new_node = super :status
        new_node.code = code
        new_node
      end

      def code
        read_attr :code
      end

      def code=(var)
        write_attr :code, var
      end
    end

    MUC_NS = "http://jabber.org/protocol/muc#user"

    register :muc_user, :muc_user

    def affiliation
      create_ia[:affiliation]
    end

    def affiliation=(val)
      create_ia[:affiliation] = val
    end

    def role
      create_ia[:role]
    end

    def role=(val)
      create_ia[:role] = val
    end

    def jid
      create_ia[:jid]
    end

    def jid=(val)
      create_ia[:jid] = val
    end

    private
      def create_muc
        unless create_muc = find_first('ns:x', :ns => MUC_NS)
           self << (create_muc = XMPPNode.new('x', self.document))
           create_muc.namespace = MUC_NS
         end
         create_muc
      end

      def create_ia
       unless create_ia = create_muc.find_first('ns:item', :ns => self.class.registered_ns)
          create_muc << (create_ia = XMPPNode.new('item', self.document))
        end
        create_ia
      end
  end # MUC

end # Presence
end # Stanza
end # Blather
