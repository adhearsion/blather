module Blather
class Stanza
class Iq

  class Query < Iq
    register :query, :query

    ##
    # Ensure the namespace is set to the query node
    def self.new(type = nil)
      node = super
      node.query
      node
    end

    ##
    # Kill the query node before running inherit
    def inherit(node)
      query.remove
      super
    end

    ##
    # Query node accessor
    # This will ensure there actually is a query node
    def query
      q = if self.class.registered_ns
        find_first('query_ns:query', :query_ns => self.class.registered_ns)
      else
        find_first('query')
      end

      unless q
        (self << (q = XMPPNode.new('query', self.document)))
        q.namespace = self.class.registered_ns
      end
      q
    end

    ##
    # A query reply should have type set to "result"
    def reply
      elem = super
      elem.type = :result
      elem
    end

    ##
    # A query reply should have type set to "result"
    def reply!
      super
      self.type = :result
      self
    end
  end #Query

end #Iq
end #Stanza
end