module Blather
class Stanza
class Message

  class MUCUser < Message
    register :muc_user, :x, "http://jabber.org/protocol/muc#user"

    def self.new(*args)
      new_node = super
      new_node.muc_user
      new_node
    end

    def inherit(node)
      muc_user.remove
      super
      self
    end

    def password
      find_password_node && password_node.content
    end

    def password=(var)
      password_node.content = var
    end

    def invite?
      !!find_invite_node
    end

    def invite_decline?
      !!find_decline_node
    end

    def muc_user
      unless muc_user = find_first('ns:x', :ns => self.class.registered_ns)
        self << (muc_user = XMPPNode.new('x', self.document))
        muc_user.namespace = self.class.registered_ns
      end
      muc_user
    end

    def password_node
      unless pw = find_password_node
        muc_user << (pw = XMPPNode.new('password', self.document))
      end
      pw
    end

    def find_password_node
      muc_user.find_first 'ns:password', :ns => self.class.registered_ns
    end

    def invite
      if invite = find_invite_node
        Invite.new invite
      else
        muc_user << (invite = Invite.new nil, nil, nil, self.document)
        invite
      end
    end

    def find_invite_node
      muc_user.find_first 'ns:invite', :ns => self.class.registered_ns
    end

    def decline
      if decline = find_decline_node
        Decline.new decline
      else
        muc_user << (decline = Decline.new nil, nil, nil, self.document)
        decline
      end
    end

    def find_decline_node
      muc_user.find_first 'ns:decline', :ns => self.class.registered_ns
    end

    class InviteBase < XMPPNode
      def self.new(element_name, to = nil, from = nil, reason = nil, document = nil)
        new_node = super element_name, document

        case to
        when self
          to.document ||= document
          return to
        when Nokogiri::XML::Node
          new_node.inherit to
        when Hash
          new_node.to = to[:to]
          new_node.from = to[:from]
          new_node.reason = to[:reason]
        else
          new_node.to = to
          new_node.from = from
          new_node.reason = reason
        end
        new_node
      end

      def to
        read_attr :to
      end

      def to=(val)
        write_attr :to, val
      end

      def from
        read_attr :from
      end

      def from=(val)
        write_attr :from, val
      end

      def reason
        reason_node.content.strip
      end

      def reason=(val)
        reason_node.content = val
      end

      def reason_node
        unless reason = find_first('ns:reason', :ns => MUCUser.registered_ns)
          self << (reason = XMPPNode.new('reason', self.document))
        end
        reason
      end
    end

    class Invite < InviteBase
      def self.new(*args)
        new_node = super :invite, *args
      end
    end

    class Decline < InviteBase
      def self.new(*args)
        new_node = super :decline, *args
      end
    end
  end # MUC

end # Presence
end # Stanza
end # Blather
