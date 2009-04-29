module Blather
class Stanza

  class DiscoItems < Disco
    register :disco_items, nil, 'http://jabber.org/protocol/disco#items'

    def initialize(type = nil, node = nil, items = [])
      super type
      self.node = node
      [items].flatten.each do |item|
        query << (item.is_a?(Item) ? item : Item.new(item[:jid], item[:node], item[:name]))
      end
    end

    def items
      items = query.find('item')
      items = query.find('query_ns:item', :query_ns => self.class.ns) if items.empty?
      items.map { |i| Item.new i }
    end

    def node=(node)
      query.attributes[:node] = node
    end

    def node
      query.attributes[:node]
    end

    class Item < XMPPNode
      def initialize(jid, node = nil, name = nil)
        super :item

        if jid.is_a?(XML::Node)
          self.inherit jid
        else
          self.jid = jid
          self.node = node
          self.name = name
        end
      end

      def jid
        (j = attributes[:jid]) ? JID.new(j) : nil
      end
      attribute_writer :jid

      attribute_accessor :node, :name, :to_sym => false      
    end

    def eql?(other)
      other.kind_of?(self.class) &&
      other.jid == self.jid &&
      other.node == self.node &&
      other.name == self.name
    end
  end

end #Stanza
end #Blather
