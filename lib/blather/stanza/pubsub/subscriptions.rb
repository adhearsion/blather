module Blather
class Stanza
class PubSub

  class Subscriptions < PubSub
    register :pubsub_subscriptions, :pubsub_subscriptions, self.ns

    include Enumerable

    ##
    # Ensure the namespace is set to the query node
    def initialize(type = nil, host = nil)
      super type
      self.to = host
      subscriptions
    end

    ##
    # Kill the pubsub node before running inherit
    def inherit(node)
      subscriptions.remove!
      super
    end

    def subscriptions
      aff = pubsub.find_first('//pubsub_ns:subscriptions', :pubsub_ns => self.class.ns)
      (self.pubsub << (aff = XMPPNode.new('subscriptions'))) unless aff
      aff
    end

    def [](subscription)
      list[subscription]
    end

    def each(&block)
      list.each &block
    end

    def size
      list.size
    end

    def list
      @subscription_list ||= begin
        items = subscriptions.find('//pubsub_ns:subscription', :pubsub_ns => self.class.ns)
        items.inject({}) do |hash, item|
          hash[item.attributes[:subscription].to_sym] ||= []
          hash[item.attributes[:subscription].to_sym] << item.attributes[:node]
          hash
        end
      end
    end
  end #Subscriptions

end #PubSub
end #Stanza
end #Blather
