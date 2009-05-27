module Blather
class Stanza
class PubSub

  class Subscriptions < PubSub
    register :pubsub_subscriptions, :subscriptions, self.registered_ns

    include Enumerable
    alias_method :find, :xpath

    ##
    # Ensure the namespace is set to the query node
    def self.new(type = nil, host = nil)
      new_node = super type
      new_node.to = host
      new_node.subscriptions
      new_node
    end

    ##
    # Kill the pubsub node before running inherit
    def inherit(node)
      subscriptions.remove
      super
    end

    def subscriptions
      aff = pubsub.find_first('subscriptions', self.class.registered_ns)
      (self.pubsub << (aff = XMPPNode.new('subscriptions', self.document))) unless aff
      aff
    end

    def each(&block)
      list.each &block
    end

    def size
      list.size
    end

    def list
      subscriptions.find('//ns:subscription', :ns => self.class.registered_ns).inject({}) do |hash, item|
        hash[item[:subscription].to_sym] ||= []
        hash[item[:subscription].to_sym] << item[:node]
        hash
      end
    end
  end #Subscriptions

end #PubSub
end #Stanza
end #Blather
