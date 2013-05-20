module Blather
class Stanza
class PubSub

  # # PubSub Subscriptions Stanza
  #
  # [XEP-0060 Section 5.6 Retrieve Subscriptions](http://xmpp.org/extensions/xep-0060.html#entity-subscriptions)
  #
  # @handler :pubsub_subscriptions
  class Subscriptions < PubSub
    register :pubsub_subscriptions, :subscriptions, self.registered_ns

    include Enumerable
    alias_method :find, :xpath

    # Overrides the parent to ensure a subscriptions node is created
    # @private
    def self.new(type = nil, host = nil)
      new_node = super type
      new_node.to = host
      new_node.subscriptions
      new_node
    end

    # Overrides the parent to ensure the subscriptions node is destroyed
    # @private
    def inherit(node)
      subscriptions.remove
      super
    end

    # Get or create the actual subscriptions node
    #
    # @return [Blather::XMPPNode]
    def subscriptions
      aff = pubsub.at_xpath('ns:subscriptions', ns: self.class.registered_ns)
      unless aff
        (self.pubsub << (aff = XMPPNode.new('subscriptions', self.document)))
      end
      aff
    end

    # Iterate over the list of subscriptions
    #
    # @yieldparam [Hash] subscription
    # @see {#list}
    def each(&block)
      list.each &block
    end

    # Get the size of the subscriptions list
    #
    # @return [Fixnum]
    def size
      list.size
    end

    # Get a hash of subscriptions
    #
    # @example
    #   { :subscribed => [{:node => 'node1', :jid => 'francisco@denmark.lit', :subid => 'fd8237yr872h3f289j2'}, {:node => 'node2', :jid => 'francisco@denmark.lit', :subid => 'h8394hf8923ju'}],
    #     :unconfigured => [{:node => 'node3', :jid => 'francisco@denmark.lit'}],
    #     :pending => [{:node => 'node4', :jid => 'francisco@denmark.lit'}],
    #     :none => [{:node => 'node5', :jid => 'francisco@denmark.lit'}] }
    #
    # @return [Hash]
    def list
      subscriptions.xpath('//ns:subscription', :ns => self.class.registered_ns).inject({}) do |hash, item|
        hash[item[:subscription].to_sym] ||= []
        sub = {
          :node => item[:node],
          :jid => item[:jid]
        }
        sub[:subid] = item[:subid] if item[:subid]
        hash[item[:subscription].to_sym] << sub
        hash
      end
    end
  end  # Subscriptions

end  # PubSub
end  # Stanza
end  # Blather
