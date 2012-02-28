require 'blather/stanza/muc/muc_user_base'

module Blather
class Stanza
class Message

  class MUCUser < Message
    include Blather::Stanza::MUC::MUCUserBase

    def self.new(to = nil, body = nil, type = :normal)
      super
    end

    def invite?
      !!find_invite_node
    end

    def invite_decline?
      !!find_decline_node
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
