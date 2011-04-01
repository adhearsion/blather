module Blather
class Stanza
class Iq
module MUC

  class Admin < Query
    register :admin, :admin, 'http://jabber.org/protocol/muc#admin'

    def self.new(type = nil, to = nil)
      node           = super(type)
      node.to        = to
      node
    end

    # <iq from='crone1@shakespeare.lit/desktop'
    #     id='member3'
    #     to='darkcave@chat.shakespeare.lit'
    #     type='get'>
    #   <query xmlns='http://jabber.org/protocol/muc#admin'>
    #     <item affiliation='member'/>
    #   </query>
    # </iq>
    class Members < Admin
      def self.new(*args)
        query = super(:get, *args)
        query.create_item
        query
      end

      def create_item # @private
        unless create_item = query.find_first('ns:item', :ns => self.class.registered_ns)
          query << (create_item = XMPPNode.new('item', self.document))
          create_item[:affiliation] = 'member'
        end
        create_item
      end
    end

  end #Admin

end #MUC
end #Iq
end #Stanza
end
