module Blather
class Stanza
class PubSub

  # # PubSub Affiliations Stanza
  #
  # [XEP-0060 Section 8.9 - Manage Affiliations](http://xmpp.org/extensions/xep-0060.html#owner-affiliations)
  #
  # @handler :pubsub_affiliations
  class Affiliations < PubSub
    register :pubsub_affiliations, :affiliations, self.registered_ns

    include Enumerable
    alias_method :find, :xpath

    # Overrides the parent to ensure an affiliation node is created
    # @private
    def self.new(type = nil, host = nil)
      new_node = super
      new_node.affiliations
      new_node
    end

    # Kill the affiliations node before running inherit
    # @private
    def inherit(node)
      affiliations.remove
      super
    end

    # Get or create the affiliations node
    #
    # @return [Blather::XMPPNode]
    def affiliations
      aff = pubsub.at_xpath('ns:affiliations', :ns => self.class.registered_ns)
      unless aff
        self.pubsub << (aff = XMPPNode.new('affiliations', self.document))
      end
      aff
    end

    # Convenience method for iterating over the list
    #
    # @see #list for the format of the yielded input
    def each(&block)
      list.each &block
    end

    # Get the number of affiliations
    #
    # @return [Fixnum]
    def size
      list.size
    end

    # Get the hash of affilations as affiliation-type => [nodes]
    #
    # @example
    #
    #     { :owner => ['node1', 'node2'],
    #       :publisher => ['node3'],
    #       :outcast => ['node4'],
    #       :member => ['node5'],
    #       :none => ['node6'] }
    #
    # @return [Hash<String => Array<String>>]
    def list
      items = affiliations.xpath('//ns:affiliation', :ns => self.class.registered_ns)
      items.inject({}) do |hash, item|
        hash[item[:affiliation].to_sym] ||= []
        hash[item[:affiliation].to_sym] << item[:node]
        hash
      end
    end
  end  # Affiliations

end  # PubSub
end  # Stanza
end  # Blather
