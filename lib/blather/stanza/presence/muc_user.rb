module Blather
class Stanza
class Presence

  class MUCUser < Status
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

    def affiliation
      item.affiliation
    end

    def affiliation=(val)
      item.affiliation = val
    end

    def role
      item.role
    end

    def role=(val)
      item.role = val
    end

    def jid
      item.jid
    end

    def jid=(val)
      item.jid = val
    end

    def status_codes
      status.map &:code
    end

    def status_codes=(val)
      muc_user.remove_children :status
      val.each do |code|
        muc_user << Status.new(code)
      end
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

    def muc_user
      unless muc_user = find_first('ns:x', :ns => self.class.registered_ns)
        self << (muc_user = XMPPNode.new('x', self.document))
        muc_user.namespace = self.class.registered_ns
      end
      muc_user
    end

    def item
      if item = muc_user.find_first('ns:item', :ns => self.class.registered_ns)
        Item.new item
      else
        muc_user << (item = Item.new nil, nil, nil, self.document)
        item
      end
    end

    def status
      muc_user.find('ns:status', :ns => self.class.registered_ns).map do |status|
        Status.new status
      end
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

    class Item < XMPPNode
      def self.new(affiliation = nil, role = nil, jid = nil, document = nil)
        new_node = super :item, document

        case affiliation
        when self
          affiliation.document ||= document
          return affiliation
        when Nokogiri::XML::Node
          new_node.inherit affiliation
        when Hash
          new_node.affiliation = affiliation[:affiliation]
          new_node.role = affiliation[:role]
          new_node.jid = affiliation[:jid]
        else
          new_node.affiliation = affiliation
          new_node.role = role
          new_node.jid = jid
        end
        new_node
      end

      def affiliation
        read_attr :affiliation, :to_sym
      end

      def affiliation=(val)
        write_attr :affiliation, val
      end

      def role
        read_attr :role, :to_sym
      end

      def role=(val)
        write_attr :role, val
      end

      def jid
        read_attr :jid
      end

      def jid=(val)
        write_attr :jid, val
      end
    end

    class Status < XMPPNode
      def self.new(code = nil)
        new_node = super :status

        case code
        when self.class
          return code
        when Nokogiri::XML::Node
          new_node.inherit code
        when Hash
          new_node.code = code[:code]
        else
          new_node.code = code
        end
        new_node
      end

      def code
        read_attr :code, :to_i
      end

      def code=(val)
        write_attr :code, val
      end
    end

    class Invite < XMPPNode
      def self.new(to = nil, from = nil, reason = nil, document = nil)
        new_node = super :invite, document

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
  end # MUC

end # Presence
end # Stanza
end # Blather
