module Blather
class Stanza
class PubSub

  class Affiliations < PubSub
    register :pubsub_affiliations, :pubsub_affiliations, self.ns

    include Enumerable

    ##
    # Ensure the namespace is set to the query node
    def initialize(type = nil, host = nil)
      super type
      self.to = host
      affiliations
    end

    ##
    # Kill the pubsub node before running inherit
    def inherit(node)
      affiliations.remove!
      super
    end

    def affiliations
      aff = pubsub.find_first('//pubsub_ns:affiliations', :pubsub_ns => self.class.ns)
      (self.pubsub << (aff = XMPPNode.new('affiliations'))) unless aff
      aff
    end

    def [](affiliation)
      list[affiliation]
    end

    def each(&block)
      list.each &block
    end

    def size
      list.size
    end

    def list
      @affiliation_list ||= begin
        items = affiliations.find('//pubsub_ns:affiliation', :pubsub_ns => self.class.ns)
        items.inject({}) do |hash, item|
          hash[item.attributes[:affiliation].to_sym] ||= []
          hash[item.attributes[:affiliation].to_sym] << item.attributes[:node]
          hash
        end
      end
    end
  end #Affiliations

end #PubSub
end #Stanza
end #Blather
