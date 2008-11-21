module Blather

  class RosterItem
    attr_reader :jid,
                :ask,
                :statuses

    attr_accessor :name,
                  :groups

    def initialize(item)
      @statuses = []

      if item.is_a?(JID)
        self.jid = item.stripped
      elsif item.is_a?(XMPPNode)
        self.jid          = JID.new(item['jid']).stripped
        self.name         = item['name']
        self.subscription = item['subscription']
        self.ask          = item['ask']
        item.groups.each { |g| self.groups << g }
      end
    end

    def jid=(jid)
      @jid = JID.new(jid).stripped
    end

    VALID_SUBSCRIPTION_TYPES = [:both, :from, :none, :remove, :to].freeze
    def subscription=(sub)
      raise ArgumentError, "Invalid Type (#{sub}), use: #{VALID_SUBSCRIPTION_TYPES*' '}" if
        sub && !VALID_SUBSCRIPTION_TYPES.include?(sub = sub.to_sym)
      @subscription = sub ? sub : :none
    end

    def subscription
      @subscription || :none
    end

    def ask=(ask)
      raise ArgumentError, "Invalid Type (#{ask}), use: #{VALID_SUBSCRIPTION_TYPES*' '}" if ask && (ask = ask.to_sym) != :subscribe
      @ask = ask ? ask : nil
    end

    def status=(presence)
      @statuses.delete_if { |s| s.from == presence.from }
      @statuses << presence
      @statuses.sort!
    end

    def status(resource = nil)
      top = resource ? @statuses.detect { |s| s.from.resource == resource } : @statuses.first
    end

    def to_stanza(type = nil)
      r = Stanza::Iq::Roster.new type
      n = Stanza::Iq::Roster::RosterItem.new jid, name, subscription, ask
      r.query << n
      n.groups = groups
      r
    end
  end #RosterItem

end