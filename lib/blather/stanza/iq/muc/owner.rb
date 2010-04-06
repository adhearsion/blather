module Blather
class Stanza
class Iq
module MUC

  class Owner < Query
    register :owner, :owner, 'http://jabber.org/protocol/muc#owner'

    def self.new(type = nil, to = nil)
      node           = super(type)
      node.to        = to
      node
    end
    
    class Configure < Owner
      DATA_NAMESPACE = 'jabber:x:data'
      
      def data=(data = :default)
        create_data[:type] = 'submit'
        unless data.blank? || data == :default
          raise "Invalid data format" unless data.is_a?(Hash)
          data.each {|key, value|
            create_field = XMPPNode.new('field', self.document)
            create_field[:var] = key
            
            create_field_value = XMPPNode.new('value', self.document)
            if [TrueClass, FalseClass].include?(value.class)
              value = value ? 1 : 0
            end
            create_field_value.content = value.to_s
            
            create_field << create_field_value
            create_data  << create_field
          }      
        end
      end
      
      def data
        items = create_data.find('//ns:field', :ns => self.class.registered_ns)
        items.inject({}) do |hash, item|
          key       = item[:var]
          value     = item.find_first('ns:value', :ns => self.class.registered_ns)
          value     = value.content
          hash[key] = value
          hash
        end
      end

      protected    
        def create_data
          unless create_data = query.find_first('ns:x', :ns => DATA_NAMESPACE)
            query << (create_data = XMPPNode.new('x', self.document))
            create_data.namespace = DATA_NAMESPACE
          end
          create_data
        end
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
        return if reason.blank?
        create_reason.content = reason
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