require 'blather/stanza/muc/muc_user_base'

module Blather
class Stanza
class Presence

  class MUCUser < Status
    include Blather::Stanza::MUC::MUCUserBase

    register :muc_user_presence, :x, "http://jabber.org/protocol/muc#user"

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
  end # MUC

end # Presence
end # Stanza
end # Blather
