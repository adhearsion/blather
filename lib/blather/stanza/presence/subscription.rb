module Blather
class Stanza
class Presence

  class Subscription < Presence
    register :subscription, :subscription

    def initialize(to = nil, type = nil)
      super()
      self.to = to
      self.type = type
    end

    def inherit(node)
      inherit_attrs node.attributes
      self
    end

    def to=(to)
      super JID.new(to).stripped
    end

    ##
    # Create an approve stanza
    def approve!
      self.type = :subscribed
      reply_if_needed!
    end

    ##
    # Create a refuse stanza
    def refuse!
      self.type = :unsubscribed
      reply_if_needed!
    end

    ##
    # Create an unsubscribe stanza
    def unsubscribe!
      self.type = :unsubscribe
      reply_if_needed!
    end

    ##
    # Create a cancel stanza
    def cancel!
      self.type = :unsubscribed
      reply_if_needed!
    end

    ##
    # Create a request stanza
    def request!
      self.type = :subscribe
      reply_if_needed!
    end

    def request?
      self.type == :subscribe
    end

  end #Subscription

end #Presence
end #Stanza
end
