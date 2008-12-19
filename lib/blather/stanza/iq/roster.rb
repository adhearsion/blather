module Blather
class Stanza
class Iq

  class Roster < Query
    register :roster, nil, 'jabber:iq:roster'

    def self.new(type = :get, item = nil)
      elem = super(type)
      elem.query << item
      elem
    end

    def inherit(node)
      items.each { |i| i.remove! }
      @items = nil
      super
      items.each { |i| query << RosterItem.new(i); i.remove! }
      @items = nil
      self
    end

    def items
      @items ||= query.find('item')#.map { |g| RosterItem.new g }
    end

    class RosterItem < XMPPNode
      def self.new(jid = nil, name = nil, subscription = nil, ask = nil)
        elem = super('item')
        if jid.is_a?(XML::Node)
          elem.inherit jid
        else
          elem.jid = jid
          elem.name = name
          elem.subscription = subscription
          elem.ask = ask
        end
        elem
      end

      def jid
        (j = self['jid']) ? JID.new(j) : nil
      end

      def jid=(jid)
        attributes.remove :jid
        self['jid'] = jid.to_s if jid
      end

      def name
        self['name']
      end

      def name=(name)
        attributes.remove :name
        self['name'] = name if name
      end

      def subscription
        self['subscription'].to_sym if self['subscription']
      end

      def subscription=(subscription)
        attributes.remove :subscription
        self['subscription'] = subscription.to_s if subscription
      end

      def ask
        self['ask'].to_sym if self['ask']
      end

      def ask=(ask)
        attributes.remove :ask
        self['ask'] = ask if ask
      end

      def groups
        @groups ||= find('group').map { |g| g.content }
      end

      def groups=(grps)
        find('group').each { |g| g.remove! }
        @groups = nil

        grps.uniq.each { |g| add_node XML::Node.new('group', g.to_s) } if grps
      end

      def to_stanza
        Roster.new(:set, self)
      end
    end #RosterItem
  end #Roster

end #Iq
end #Stanza
end