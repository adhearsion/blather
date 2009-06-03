module Blather
class Stanza
class Iq

  class Roster < Query
    register :roster, nil, 'jabber:iq:roster'

    ##
    # Any new items are added to the query
    def self.new(type = nil, item = nil)
      node = super type
      node.query << item if item
      node
    end

    ##
    # Inherit the XMPPNode to create a proper Roster object.
    # Creates RosterItem objects out of each roster item as well.
    def inherit(node)
      # remove the current set of nodes
      remove_children :item
      super
      # transmogrify nodes into RosterItems
      items.each { |i| query << RosterItem.new(i); i.remove }
      self
    end

    ##
    # Roster items
    def items
      query.find('//ns:item', :ns => self.class.registered_ns).map { |i| RosterItem.new(i) }
    end

    class RosterItem < XMPPNode
      ##
      # [jid] may be either a JID or XMPPNode. 
      # [name] name alias of the given JID
      # [subscription] subscription type
      # [ask] ask subscription sub-state
      def self.new(jid = nil, name = nil, subscription = nil, ask = nil)
        new_node = super :item

        case jid
        when Nokogiri::XML::Node
          new_node.inherit jid
        when Hash
          new_node.jid = jid[:jid]
          new_node.name = jid[:name]
          new_node.subscription = jid[:subscription]
          new_node.ask = jid[:ask]
        else
          new_node.jid = jid
          new_node.name = name
          new_node.subscription = subscription
          new_node.ask = ask
        end
        new_node
      end

      ##
      # Roster item's JID
      def jid
        (j = self[:jid]) ? JID.new(j) : nil
      end
      attribute_writer :jid

      attribute_accessor :name

      attribute_accessor :subscription, :ask, :call => :to_sym

      ##
      # The groups roster item belongs to
      def groups
        find('child::*[local-name()="group"]').map { |g| g.content }
      end

      ##
      # Set the roster item's groups
      # must be an array
      def groups=(new_groups)
        remove_children :group
        if new_groups
          new_groups.uniq.each do |g|
            self << (group = XMPPNode.new(:group, self.document))
            group.content = g
          end
        end
      end

      ##
      # Convert the roster item to a proper stanza all wrapped up
      # This facilitates new subscriptions
      def to_stanza
        Roster.new(:set, self)
      end
    end #RosterItem
  end #Roster

end #Iq
end #Stanza
end