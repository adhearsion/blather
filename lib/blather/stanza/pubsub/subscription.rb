module Blather
class Stanza
class PubSub

  # # PubSub Subscription Stanza
  #
  # [XEP-0060 Section 8.8 Manage Subscriptions](http://xmpp.org/extensions/xep-0060.html#owner-subscriptions)
  #
  # @handler :pubsub_subscription
  class Subscription < PubSub
    VALID_TYPES = [:none, :pending, :subscribed, :unconfigured]

    register :pubsub_subscription, :subscription, self.registered_ns

    # Create a new subscription request node
    #
    # @param [Blather::Stanza::Iq::VALID_TYPES] type the IQ type
    # @param [String] host the host to send the request to
    # @param [String] node the node to look for requests on
    # @param [Blather::JID, #to_s] jid the JID of the subscriber
    # @param [String] subid the subscription ID
    # @param [VALID_TYPES] subscription the subscription type
    def self.new(type = :result, host = nil, node = nil, jid = nil, subid = nil, subscription = nil)
      new_node = super(type, host)
      new_node.node = node
      new_node.jid = jid
      new_node.subid = subid
      new_node.subscription = subscription
      new_node
    end

    # Check if the type is none
    #
    # @return [Boolean]
    def none?
      self.subscription == :none
    end

    # Check if the type is pending
    #
    # @return [Boolean]
    def pending?
      self.subscription == :pending
    end

    # Check if the type is subscribed
    #
    # @return [Boolean]
    def subscribed?
      self.subscription == :subscribed
    end

    # Check if the type is unconfigured
    #
    # @return [Boolean]
    def unconfigured?
      self.subscription == :unconfigured
    end

    # Get the JID of the subscriber
    #
    # @return [Blather::JID]
    def jid
      JID.new(subscription_node[:jid])
    end

    # Set the JID of the subscriber
    #
    # @param [Blather::JID, #to_s] jid
    def jid=(jid)
      subscription_node[:jid] = jid
    end

    # Get the name of the subscription node
    #
    # @return [String]
    def node
      subscription_node[:node]
    end

    # Set the name of the subscription node
    #
    # @param [String] node
    def node=(node)
      subscription_node[:node] = node
    end

    # Get the ID of the subscription
    #
    # @return [String]
    def subid
      subscription_node[:subid]
    end

    # Set the ID of the subscription
    #
    # @param [String] subid
    def subid=(subid)
      subscription_node[:subid] = subid
    end

    # Get the subscription type
    #
    # @return [VALID_TYPES, nil]
    def subscription
      s = subscription_node[:subscription]
      s.to_sym if s
    end

    # Set the subscription type
    #
    # @param [VALID_TYPES, nil] subscription
    def subscription=(subscription)
      if subscription && !VALID_TYPES.include?(subscription.to_sym)
        raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}"
      end
      subscription_node[:subscription] = subscription
    end

    # Get or create the actual subscription node
    #
    # @return [Blather::XMPPNode]
    def subscription_node
      unless subscription = pubsub.find_first('ns:subscription', :ns => self.class.registered_ns)
        self.pubsub << (subscription = XMPPNode.new('subscription', self.document))
        subscription.namespace = self.pubsub.namespace
      end
      subscription
    end
  end  # Subscribe

end  # PubSub
end  # Stanza
end  # Blather
