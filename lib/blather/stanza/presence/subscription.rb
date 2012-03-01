module Blather
class Stanza
class Presence

  # # Subscription Stanza
  #
  # [RFC 3921 Section 8 - Integration of Roster Items and Presence Subscriptions](http://xmpp.org/rfcs/rfc3921.html#rfc.section.8)
  #
  # Blather handles subscription request/response through this class. It
  # provides a set of helper methods to quickly transform the stanza into a
  # response.
  #
  # @handler :subscription
  class Subscription < Presence
    register :subscription, :subscription

    # Create a new Subscription stanza
    #
    # @param [Blather::JID, #to_s] to the JID to subscribe to
    # @param [Symbol, nil] type the subscription type
    def self.new(to = nil, type = nil)
      node = super()
      node.to = to
      node.type = type
      node
    end

    # Set the to value on the stanza
    #
    # @param [Blather::JID, #to_s] to a JID to subscribe to
    def to=(to)
      super JID.new(to).stripped
    end

    # Transform the stanza into an approve stanza
    # makes approving requests simple
    #
    # @example approve an incoming request
    #   subscription(:request?) { |s| write_to_stream s.approve! }
    # @return [self]
    def approve!
      self.type = :subscribed
      reply_if_needed!
    end

    # Transform the stanza into a refuse stanza
    # makes refusing requests simple
    #
    # @example refuse an incoming request
    #   subscription(:request?) { |s| write_to_stream s.refuse! }
    # @return [self]
    def refuse!
      self.type = :unsubscribed
      reply_if_needed!
    end

    # Transform the stanza into an unsubscribe stanza
    # makes unsubscribing simple
    #
    # @return [self]
    def unsubscribe!
      self.type = :unsubscribe
      reply_if_needed!
    end

    # Transform the stanza into a cancel stanza
    # makes canceling simple
    #
    # @return [self]
    def cancel!
      self.type = :unsubscribed
      reply_if_needed!
    end

    # Transform the stanza into a request stanza
    # makes requests simple
    #
    # @return [self]
    def request!
      self.type = :subscribe
      reply_if_needed!
    end

    # Check if the stanza is a request
    #
    # @return [true, false]
    def request?
      self.type == :subscribe
    end

  end #Subscription

end #Presence
end #Stanza
end
