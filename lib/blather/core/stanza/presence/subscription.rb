module Blather
class Stanza
class Presence

  class Subscription < Presence
    register :subscription

    def self.new(to = nil, type = nil)
      elem = super()
      elem.to = to
      elem.type = type
      elem
    end

    def inherit(node)
      inherit_attrs node.attributes
      self
    end

    def to=(to)
      super JID.new(to).stripped
    end

    def approve!
      self.type = :subscribed
      morph_to_reply
    end

    def refuse!
      self.type = :unsubscribed
      morph_to_reply
    end

    def unsubscribe!
      self.type = :unsubscribe
      morph_to_reply
    end

    def cancel!
      self.type = :unsubscribed
      morph_to_reply
    end

    def request!
      self.type = :subscribe
      morph_to_reply
    end

    def request?
      self.type == :subscribe
    end

  private
    def morph_to_reply
      self.to = self.from if self.from
      self.from = nil
      self
    end
  end #Subscription

end #Presence
end #Stanza
end