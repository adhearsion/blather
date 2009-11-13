module Blather
class Stanza

  class DiscoItems < Disco
    register :disco_items, nil, 'http://jabber.org/protocol/disco#items'

    def self.new(type = nil, node = nil, items = [])
      new_node = super type
      new_node.node = node
      [items].flatten.each { |item| new_node.query << Item.new(item) }
      new_node
    end

    def items
      query.find('//query_ns:item', :query_ns => self.class.registered_ns).map { |i| Item.new i }
    end

    def node=(node)
      query[:node] = node
    end

    def node
      query[:node]
    end

    class Item < XMPPNode
      def self.new(jid, node = nil, name = nil)
        new_node = super :item

        case jid
        when Nokogiri::XML::Node
          new_node.inherit jid
        when Hash
          new_node.jid = jid[:jid]
          new_node.node = jid[:node]
          new_node.name = jid[:name]
        else
          new_node.jid = jid
          new_node.node = node
          new_node.name = name
        end
        new_node
      end

      def jid
        (j = self[:jid]) ? JID.new(j) : nil
      end

      def jid=(jid)
        write_attr :jid, jid
      end

      def node
        read_attr :node
      end

      def node=(node)
        write_attr :node, node
      end

      def name
        read_attr :name
      end

      def name=(name)
        write_attr :name, name
      end

      def eql?(o)
        raise "Cannot compare #{self.class} with #{o.class}" unless o.is_a?(self.class)
        o.jid == self.jid &&
        o.node == self.node &&
        o.name == self.name
      end
      alias_method :==, :eql?
    end
  end

end #Stanza
end #Blather
