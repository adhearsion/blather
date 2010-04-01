module Blather
class Stanza
class Iq
module MUC

  class Owner < Query
    DATA_NAMESPACE = "jabber:x:data"
    register :owner, :owner, "http://jabber.org/protocol/muc#owner"

    def self.new(type = nil, to = nil, data_type = nil)
      node           = super(type)
      node.to        = to
      node.data_type = data_type
      node
    end
    
    def data_type=(type)
      create_data[:type] = type
    end
    
    protected    
      def create_data
        unless create_data = find_first('ns:x', :ns => DATA_NAMESPACE)
          self << (create_data = XMPPNode.new('x', self.document))
          create_data.namespace = (DATA_NAMESPACE)
        end
        create_data
      end
    
  end #Owner

end #MUC
end #Iq
end #Stanza
end