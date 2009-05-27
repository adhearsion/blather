module Blather
class Stanza
class PubSub

  class Affiliations < PubSub
    register :pubsub_affiliations, :affiliations, self.registered_ns

    include Enumerable
    alias_method :find, :xpath

    def self.new(type = nil, host = nil)
      new_node = super
      new_node.affiliations
      new_node
    end

    ##
    # Kill the affiliations node before running inherit
    def inherit(node)
      affiliations.remove
      super
    end

    def affiliations
      aff = pubsub.find_first('pubsub_ns:affiliations', :pubsub_ns => self.class.registered_ns)
      self.pubsub << (aff = XMPPNode.new('affiliations', self.document)) unless aff
      aff
    end

    def each(&block)
      list.each &block
    end

    def size
      list.size
    end

    def list
      items = affiliations.find('//ns:affiliation', :ns => self.class.registered_ns)
      items.inject({}) do |hash, item|
        hash[item[:affiliation].to_sym] ||= []
        hash[item[:affiliation].to_sym] << item[:node]
        hash
      end
    end
  end #Affiliations

end #PubSub
end #Stanza
end #Blather
