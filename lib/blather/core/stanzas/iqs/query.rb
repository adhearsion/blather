module Blather
  class Iq

    class Query < Iq
      register :query, :query

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
    end #Query

  end #Iq
end