module Blather
class Stanza
class Iq
module MUC

  class Owner < Query
    register :owner, :query, 'http://jabber.org/protocol/muc#owner'

    def self.new(type = nil, to = nil, config = nil)
      node    = super(type)
      node.to = to
      if config
        node.form.type  = :submit
        node.config     = config
      end
      node
    end

    # Returns the command's x:data form child
    def form
      X.find_or_create query
    end

    def config=(config)
      form.fields = config
    end

    # <iq from='crone1@shakespeare.lit/desktop'
    #     id='begone'
    #     to='heath@chat.shakespeare.lit'
    #     type='set'>
    #   <query xmlns='http://jabber.org/protocol/muc#owner'>
    #     <destroy jid='darkcave@chat.shakespeare.lit'>
    #       <reason>Macbeth doth come.</reason>
    #     </destroy>
    #   </query>
    # </iq>
    class Destroy < Owner

      def self.new(*args)
        query = super(:set, *args)
        query.create_destroy
        query
      end

      def reason=(reason)
        create_reason.content = reason unless reason.blank?
      end

      def create_reason # @private
        unless create_reason = create_destroy.find_first('ns:reason', :ns => self.class.registered_ns)
          create_destroy << (create_reason = XMPPNode.new('reason', self.document))
        end
        create_reason
      end

      def create_destroy # @private
        unless create_destroy = query.find_first('ns:destroy', :ns => self.class.registered_ns)
          query << (create_destroy = XMPPNode.new('destroy', self.document))
        end
        create_destroy
      end
    end

  end #Owner

end #MUC
end #Iq
end #Stanza
end
