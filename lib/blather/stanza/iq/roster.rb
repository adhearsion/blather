module Blather
class Stanza
class Iq

  class Roster < Query
    register :roster, nil, 'jabber:iq:roster'

    def initialize(type = nil, item = nil)
      super(type)
      query << item if item
    end

    def inherit(node)
      items.each { |i| i.remove! }
      super
      items.each { |i| query << RosterItem.new(i); i.remove! }
      self
    end

    def items
      query.find('item')#.map { |g| RosterItem.new g }
    end

    class RosterItem < XMPPNode
      def initialize(jid = nil, name = nil, subscription = nil, ask = nil)
        super('item')
        if jid.is_a?(XML::Node)
          self.inherit jid
        else
          self.jid = jid
          self.name = name
          self.subscription = subscription
          self.ask = ask
        end
      end

      def jid
        (j = attributes[:jid]) ? JID.new(j) : nil
      end

      def jid=(jid)
        attributes[:jid] = jid
      end

      def name
        attributes[:name]
      end

      def name=(name)
        attributes[:name] = name
      end

      def subscription
        attributes[:subscription].to_sym if attributes[:subscription]
      end

      def subscription=(subscription)
        attributes[:subscription] = subscription
      end

      def ask
        attributes[:ask].to_sym if attributes[:ask]
      end

      def ask=(ask)
        attributes[:ask] = ask
      end

      def groups
        @groups ||= find('group').map { |g| g.content }
      end

      def groups=(grps)
        find('group').each { |g| g.remove! }
        @groups = nil

        grps.uniq.each { |g| add_node XMPPNode.new('group', g.to_s) } if grps
      end

      def to_stanza
        Roster.new(:set, self)
      end
    end #RosterItem
  end #Roster

end #Iq
end #Stanza
end