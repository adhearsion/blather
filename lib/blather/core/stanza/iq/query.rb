module Blather
class Stanza
class Iq

  class Query < Iq
    register :query, :query

    def self.new(type)
      elem = super
      elem.query.xmlns = self.xmlns
      elem
    end

    def inherit(node)
      query.remove!
      @query = nil
      super
    end

    def query
      @query ||= if q = find_first('query')
        q
      else
        self << q = XMPPNode.new('query')
        q
      end
    end

    def reply
      elem = super
      elem.type = :result
    end

    def reply!
      self.type = :result
      super
    end
  end #Query

end #Iq
end #Stanza
end