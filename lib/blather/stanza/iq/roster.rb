module Blather
class Stanza
class Iq

  # # Roster Stanza
  #
  # [RFC 3921 Section 7 - Roster Management](http://xmpp.org/rfcs/rfc3921.html#roster)
  #
  # @handler :roster
  class Roster < Query
    register :roster, nil, 'jabber:iq:roster'

    # Create a new roster stanza and (optionally) load it with an item
    #
    # @param [<Blather::Stanza::Iq::VALID_TYPES>] type the stanza type
    # @param [Blather::XMPPNode] item a roster item
    def self.new(type = nil, item = nil)
      node = super type
      node.query << item if item
      node
    end

    # Inherit the XMPPNode to create a proper Roster object.
    # Creates RosterItem objects out of each roster item as well.
    #
    # @param [Blather::XMPPNode] node a node to inherit
    def inherit(node)
      # remove the current set of nodes
      remove_children :item
      super
      # transmogrify nodes into RosterItems
      items.each { |i| query << RosterItem.new(i); i.remove }
      self
    end

    # The list of roster items
    #
    # @return [Array<Blather::Stanza::Iq::Roster::RosterItem>]
    def items
      query.xpath('//ns:item', :ns => self.class.registered_ns).map do |i|
        RosterItem.new i
      end
    end

    # # RosterItem Fragment
    #
    # Individual roster items.
    # This is a convenience class to attach methods to the node
    class RosterItem < XMPPNode

      register :item, Roster.registered_ns

      # Create a new RosterItem
      # @overload new(XML::Node)
      #   Create a RosterItem by inheriting a node
      #   @param [XML::Node] node an xml node to inherit
      # @overload new(opts)
      #   Create a RosterItem through a hash of options
      #   @param [Hash] opts the options
      #   @option opts [Blather::JID, String, nil] :jid the JID of the item
      #   @option opts [String, nil] :name the alias to give the JID
      #   @option opts [Symbol, nil] :subscription the subscription status of
      #   the RosterItem must be one of
      #   Blather::RosterItem::VALID_SUBSCRIPTION_TYPES
      #   @option opts [:subscribe, nil] :ask the ask value of the RosterItem
      #   @option opts [Array<#to_s>] :groups the group names the RosterItem is a member of
      # @overload new(jid = nil, name = nil, subscription = nil, ask = nil)
      #   @param [Blather::JID, String, nil] jid the JID of the item
      #   @param [String, nil] name the alias to give the JID
      #   @param [Symbol, nil] subscription the subscription status of the
      #   RosterItem must be one of
      #   Blather::RosterItem::VALID_SUBSCRIPTION_TYPES
      #   @param [:subscribe, nil] ask the ask value of the RosterItem
      #   @param [Array<#to_s>] groups the group names the RosterItem is a member of
      def self.new(jid = nil, name = nil, subscription = nil, ask = nil, groups = nil)
        new_node = super :item

        case jid
        when Nokogiri::XML::Node
          new_node.inherit jid
        when Hash
          new_node.jid = jid[:jid]
          new_node.name = jid[:name]
          new_node.subscription = jid[:subscription]
          new_node.ask = jid[:ask]
          new_node.groups = jid[:groups]
        else
          new_node.jid = jid if jid
          new_node.name = name if name
          new_node.subscription = subscription if subscription
          new_node.ask = ask if ask
          new_node.groups = groups if groups
        end
        new_node
      end

      # Get the JID attached to the item
      #
      # @return [Blather::JID, nil]
      def jid
        (j = self[:jid]) ? JID.new(j) : nil
      end

      # Set the JID of the item
      #
      # @param [Blather::JID, String, nil] jid the new JID
      def jid=(jid)
        write_attr :jid, (jid.nil?) ? nil : JID.new(jid).stripped
      end

      # Get the item name
      #
      # @return [String, nil]
      def name
        read_attr :name
      end

      # Set the item name
      #
      # @param [#to_s] name the name of the item
      def name=(name)
        write_attr :name, name
      end

      # Get the subscription value of the item
      #
      # @return [<:both, :from, :none, :remove, :to>]
      def subscription
        read_attr :subscription, :to_sym
      end

      # Set the subscription value of the item
      #
      # @param [<:both, :from, :none, :remove, :to>] subscription
      def subscription=(subscription)
        write_attr :subscription, subscription
      end

      # Get the ask value of the item
      #
      # @return [<:subscribe, nil>]
      def ask
        read_attr :ask, :to_sym
      end

      # Set the ask value of the item
      #
      # @param [<:subscribe, nil>] ask
      def ask=(ask)
        write_attr :ask, ask
      end

      # The groups roster item belongs to
      #
      # @return [Array<String>]
      def groups
        xpath('child::*[local-name()="group"]').map { |g| g.content }
      end

      # Set the roster item's groups
      #
      # @param [Array<#to_s>] new_groups an array of group names
      def groups=(new_groups)
        remove_children :group
        if new_groups
          new_groups.uniq.each do |g|
            self << (group = XMPPNode.new(:group, self.document))
            group.content = g
          end
        end
      end

      # Convert the roster item to a proper stanza all wrapped up
      # This facilitates new subscriptions
      #
      # @return [Blather::Stanza::Iq::Roster]
      def to_stanza
        Roster.new(:set, self)
      end
    end #RosterItem
  end #Roster

end #Iq
end #Stanza
end
