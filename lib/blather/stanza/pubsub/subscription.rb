module Blather
class Stanza
class PubSub

  class Subscription < PubSub
    VALID_TYPES = [:none, :pending, :subscribed, :unconfigured]

    register :pubsub_subscription, :subscription, self.registered_ns

    def self.new(type = :result, host = nil, node = nil, jid = nil, subid = nil, subscription = nil)
      new_node = super(type, host)
      new_node.node = node
      new_node.jid = jid
      new_node.subid = subid
      new_node.subscription = subscription
      new_node
    end

    def none?
      self.type == :none
    end

    def pending?
      self.type == :pending
    end

    def subscribed?
      self.type == :subscribed
    end

    def unconfigured?
      self.type == :unconfigured
    end

    def jid
      JID.new(subscription_node[:jid])
    end

    def jid=(jid)
      subscription_node[:jid] = jid
    end

    def node
      subscription_node[:node]
    end

    def node=(node)
      subscription_node[:node] = node
    end

    def subid
      subscription_node[:subid]
    end

    def subid=(subid)
      subscription_node[:subid] = subid
    end

    def subscription
      s = subscription_node[:subscription]
      s.to_sym if s
    end

    def subscription=(subscription)
      raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}" if subscription && !VALID_TYPES.include?(subscription.to_sym)
      subscription_node[:subscription] = subscription
    end

    def subscription_node
      unless subscription = pubsub.find_first('ns:subscription', :ns => self.class.registered_ns)
        self.pubsub << (subscription = XMPPNode.new('subscription', self.document))
        subscription.namespace = self.pubsub.namespace
      end
      subscription
    end
  end #Subscribe

end #PubSub
end #Stanza
end #Blather
