module Blather

  class RosterItem
    attr_reader :jid,
                :ask,
                :statuses

    attr_accessor :name,
                  :groups

    def initialize(stream, item)
      @stream = stream
      @statuses = []

      if item.is_a?(JID)
        self.jid = item
      elsif item.is_a?(XMPPNode)
        self.jid          = JID.new(item['jid'])
        self.name         = item['name']
        self.subscription = item['subscription']
        self.ask          = item['ask']
        item.groups.each { |g| self.groups << g }
      end
    end

    def jid=(jid)
      @jid = jid.stripped
    end

    def subscription=(sub)
      @subscription = sub ? sub.to_sym : :none
    end

    def subscription
      @subscription || :none
    end

    def ask=(ask)
      @ask = ask ? ask.to_sym : nil
    end

    def status=(presence)
      @statuses.delete_if { |s| s.from == presence.from }
      @statuses << presence
      @statuses.sort!
    end

    def status(resource = nil)
      top = resource ? @statuses.detect { |s| s.jid.resoure == resource } : nil
      top || @statuses.first
    end

    def to_stanza(type = nil)
      r = Iq::Roster.new type
      n = Iq::Roster::RosterItem.new jid, name, subscription, ask
      r.query << n
      n.groups = groups
      r
    end
  end #RosterItem

end