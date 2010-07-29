module Blather
class Stanza

  # # DiscoItems Stanza
  #
  # [XEP-0030 Disco Info](http://xmpp.org/extensions/xep-0030.html#items)
  #
  # Disco Items node that provides or retreives items associated with a
  # jabbery entity
  #
  # @handler :disco_items
  class DiscoItems < Disco
    register :disco_items, nil, 'http://jabber.org/protocol/disco#items'

    # Create a new DiscoItems node
    #
    # @param [#to_s] type the IQ type
    # @param [#to_s] node the node the items are associated with
    # @param [Array<Blather::XMPPNode>] items an array of Disco::Items
    # @return [Blather::Stanza::DiscoItems]
    def self.new(type = nil, node = nil, items = [])
      new_node = super type
      new_node.node = node
      new_node.items = [items]
      new_node
    end

    # Set of items associated with the node
    #
    # @return [Array<Blather::Stanza::DiscoItems::Item>]
    def items
      query.find('//ns:item', :ns => self.class.registered_ns).map do |i|
        Item.new i
      end
    end

    # Add an array of items
    # @param items the array of items, passed directly to Item.new
    def items=(items)
      query.find('//ns:item', :ns => self.class.registered_ns).each &:remove
      if items
        [items].flatten.each { |i| self.query << Item.new(i) }
      end
    end

    # An individual Disco Item
    class Item < XMPPNode
      # Create a new Blather::Stanza::DiscoItems::Item
      #
      # @overload new(node)
      #   Create a new Item by inheriting an existing node
      #   @param [XML::Node] node an XML::Node to inherit from
      # @overload new(opts)
      #   Create a new Item through a hash of options
      #   @param [Hash] opts a hash options
      #   @option opts [Blather::JID, String] :jid the JID to attach to the item
      #   @option opts [#to_s] :node the node the item is attached to
      #   @option opts [#to_S] :name the name of the Item
      # @overload new(jid, node = nil, name  = nil)
      #   Create a new Item
      #   @param [Blather::JID, String] jid the JID to attach to the item
      #   @param [#to_s] node the node the item is attached to
      #   @param [#to_s] name the name of the Item
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

      # Get the JID attached to the node
      #
      # @return [Blather::JID, nil]
      def jid
        (j = self[:jid]) ? JID.new(j) : nil
      end

      # Set the JID of the node
      #
      # @param [Blather::JID, String, nil] jid the new JID
      def jid=(jid)
        write_attr :jid, jid
      end

      # Get the name of the node
      #
      # @return [String, nil]
      def node
        read_attr :node
      end

      # Set the name of the node
      #
      # @param [String, nil] node the new node name
      def node=(node)
        write_attr :node, node
      end

      # Get the Item name
      #
      # @return [String, nil]
      def name
        read_attr :name
      end

      # Set the Item name
      #
      # @param [#to_s] name the Item name
      def name=(name)
        write_attr :name, name
      end

      # Check for equality based on jid, node, and name
      #
      # @param [Blather::Stanza::DiscoItems::Item] o the other Item
      def eql?(o)
        unless o.is_a?(self.class)
          raise "Cannot compare #{self.class} with #{o.class}"
        end

        o.jid == self.jid &&
        o.node == self.node &&
        o.name == self.name
      end
      alias_method :==, :eql?
    end
  end

end #Stanza
end #Blather
