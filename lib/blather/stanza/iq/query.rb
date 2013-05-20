module Blather
class Stanza
class Iq

  # # Query Stanza
  #
  # This is a base class for any query based Iq stanzas. It provides a base set
  # of methods for working with query stanzas
  #
  # @handler :query
  class Query < Iq
    register :query, :query

    # Overrides the parent method to ensure a query node is created
    #
    # @see Blather::Stanza::Iq.new
    def self.new(type = nil)
      node = super
      node.query
      node
    end

    # Overrides the parent method to ensure the current query node is destroyed
    #
    # @see Blather::Stanza::Iq#inherit
    def inherit(node)
      query.remove
      super
    end

    # Query node accessor
    # If a query node exists it will be returned.
    # Otherwise a new node will be created and returned
    #
    # @return [Balather::XMPPNode]
    def query
      q = if self.class.registered_ns
        at_xpath('query_ns:query', :query_ns => self.class.registered_ns)
      else
        at_xpath('query')
      end

      unless q
        (self << (q = XMPPNode.new('query', self.document)))
        q.namespace = self.class.registered_ns
      end
      q
    end
  end #Query

end #Iq
end #Stanza
end
