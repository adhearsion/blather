module Blather
class Stanza
class Iq

  class Query < Iq
    register :query, :query

    ##
    # Ensure the namespace is set to the query node
    def initialize(type = nil)
      super()
      query.namespace = self.class.ns
    end

    ##
    # Kill the query node before running inherit
    def inherit(node)
      query.remove!
      super
    end

    ##
    # Query node accessor
    # This will ensure there actually is a query node
    def query
      q = find_first('query')
      q = find_first('//query_ns:query', :query_ns => self.class.ns) if !q && self.class.ns
      (self << (q = XMPPNode.new('query'))) unless q
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