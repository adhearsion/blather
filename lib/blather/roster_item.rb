module Blather

  # RosterItems hold internal representations of the user's roster
  # including each JID's status.
  class RosterItem
    VALID_SUBSCRIPTION_TYPES = [:both, :from, :none, :remove, :to].freeze

    attr_reader :jid,
                :ask,
                :statuses

    attr_accessor :name,
                  :groups

    def self.new(item)
      return item if item.is_a?(self)
      super
    end

    # Create a new RosterItem
    #
    # @overload initialize(jid)
    #   Create a new RosterItem based on a JID
    #   @param [Blather::JID] jid the JID object
    # @overload initialize(jid)
    #   Create a new RosterItem based on a JID string
    #   @param [String] jid a JID string
    # @overload initialize(node)
    #   Create a new RosterItem based on a stanza
    #   @param [Blather::Stanza::Iq::Roster::RosterItem] node a RosterItem
    #   stanza
    # @return [Blather::RosterItem] the new RosterItem
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

    # Set the jid
    #
    # @param [String, Blather::JID] jid the new jid
    # @see Blather::JID
    def jid=(jid)
      @jid = JID.new(jid).stripped
    end

    # Set the subscription
    # Ensures it is one of VALID_SUBSCRIPTION_TYPES
    #
    # @param [#to_sym] sub the new subscription
    def subscription=(sub)
      if sub && !VALID_SUBSCRIPTION_TYPES.include?(sub = sub.to_sym)
        raise ArgumentError, "Invalid Type (#{sub}), use: #{VALID_SUBSCRIPTION_TYPES*' '}"
      end
      @subscription = sub ? sub : :none
    end

    # Get the current subscription
    #
    # @return [:both, :from, :none, :remove, :to]
    def subscription
      @subscription || :none
    end

    # Set the ask value
    #
    # @param [nil, :subscribe] ask the new ask
    def ask=(ask)
      if ask && (ask = ask.to_sym) != :subscribe
        raise ArgumentError, "Invalid Type (#{ask}), can only be :subscribe"
      end
      @ask = ask ? ask : nil
    end

    # Set the status then sorts them according to priority
    #
    # @param [Blather::Stanza::Status] the new status
    def status=(presence)
      @statuses.delete_if { |s| s.from == presence.from }
      @statuses << presence
      @statuses.sort!
    end

    # The status with the highest priority
    #
    # @param [String, nil] resource the resource to get the status of
    def status(resource = nil)
      top = if resource
        @statuses.detect { |s| s.from.resource == resource }
      else
        @statuses.first
      end
    end

    # Translate the RosterItem into a proper stanza that can be sent over the
    # stream
    #
    # @return [Blather::Stanza::Iq::Roster]
    def to_stanza(type = nil)
      r = Stanza::Iq::Roster.new type
      n = Stanza::Iq::Roster::RosterItem.new jid, name, subscription, ask
      r.query << n
      n.groups = groups
      r
    end
  end #RosterItem

end