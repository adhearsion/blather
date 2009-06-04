module Blather

  ##
  # RosterItems hold internal representations of the user's roster
  # including each JID's status.
  class RosterItem
    VALID_SUBSCRIPTION_TYPES = [:both, :from, :none, :remove, :to]

    attr_reader :jid,
                :ask,
                :statuses

    attr_accessor :name,
                  :groups

    def self.new(item)
      return item if item.is_a?(self)
      super
    end

    ##
    # item:: can be a JID, String (a@b) or a Stanza
    def initialize(item)
      @statuses = []
      @groups = []

      case item
      when JID
        self.jid = item.stripped
      when String
        self.jid = JID.new(item).stripped
      when XMPPNode
        self.jid          = JID.new(item[:jid]).stripped
        self.name         = item[:name]
        self.subscription = item[:subscription]
        self.ask          = item[:ask]
        item.groups.each { |g| @groups << g }
      end

      @groups = [nil] if @groups.empty?
    end

    ##
    # Set the jid
    def jid=(jid)
      @jid = JID.new(jid).stripped
    end

    ##
    # Set the subscription
    # Ensures it is one of VALID_SUBSCRIPTION_TYPES
    def subscription=(sub)
      raise ArgumentError, "Invalid Type (#{sub}), use: #{VALID_SUBSCRIPTION_TYPES*' '}" if
        sub && !VALID_SUBSCRIPTION_TYPES.include?(sub = sub.to_sym)
      @subscription = sub ? sub : :none
    end

    ##
    # Get the current subscription
    # returns:: :both, :from, :none, :remove, :to or :none
    def subscription
      @subscription || :none
    end

    ##
    # Set the ask value
    # ask:: must only be nil or :subscribe
    def ask=(ask)
      raise ArgumentError, "Invalid Type (#{ask}), can only be :subscribe" if ask && (ask = ask.to_sym) != :subscribe
      @ask = ask ? ask : nil
    end

    ##
    # Set the status then sorts them according to priority
    # presence:: Status
    def status=(presence)
      @statuses.delete_if { |s| s.from == presence.from }
      @statuses << presence
      @statuses.sort!
    end

    ##
    # Return the status with the highest priority
    # if resource is set find the status of that specific resource 
    def status(resource = nil)
      top = resource ? @statuses.detect { |s| s.from.resource == resource } : @statuses.first
    end

    ##
    # Translate the RosterItem into a proper stanza that can be sent over the stream
    def to_stanza(type = nil)
      r = Stanza::Iq::Roster.new type
      n = Stanza::Iq::Roster::RosterItem.new jid, name, subscription, ask
      r.query << n
      n.groups = groups
      r
    end
  end #RosterItem

end