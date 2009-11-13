module Blather
class Stanza

  ##
  # DiscoInfo object ()
  #
  class DiscoInfo < Disco
    register :disco_info, nil, 'http://jabber.org/protocol/disco#info'

    def self.new(type = nil, node = nil, identities = [], features = [])
      new_node = super type
      new_node.node = node
      [identities].flatten.each { |id|      new_node.query << Identity.new(id)      }
      [features].flatten.each   { |feature| new_node.query << Feature.new(feature)  }
      new_node
    end

    ##
    # List of identity objects
    def identities
      query.find('//query_ns:identity', :query_ns => self.class.registered_ns).map { |i| Identity.new i }
    end

    ##
    # List of feature objects
    def features
      query.find('//query_ns:feature', :query_ns => self.class.registered_ns).map { |i| Feature.new i }
    end

    class Identity < XMPPNode
      def self.new(name, type = nil, category = nil)
        new_node = super :identity

        case name
        when Nokogiri::XML::Node
          new_node.inherit name
        when Hash
          new_node.name = name[:name]
          new_node.type = name[:type]
          new_node.category = name[:category]
        else
          new_node.name = name
          new_node.type = type
          new_node.category = category
        end
        new_node
      end

      def category
        read_attr :category, :to_sym
      end

      def category=(category)
        write_attr :category, category
      end

      def type
        read_attr :type, :to_sym
      end

      def type=(type)
        write_attr :type, type
      end

      def name
        read_attr :name
      end

      def name=(name)
        write_attr :name, name
      end

      def eql?(o)
        raise "Cannot compare #{self.class} with #{o.class}" unless o.is_a?(self.class)
        o.name == self.name &&
        o.type == self.type &&
        o.category == self.category
      end
      alias_method :==, :eql?
    end

    class Feature < XMPPNode
      def self.new(var)
        new_node = super :feature
        case var
        when Nokogiri::XML::Node
          new_node.inherit var
        else
          new_node.var = var
        end
        new_node
      end

      def var
        read_attr :var
      end

      def var=(var)
        write_attr :var, var
      end

      def eql?(o)
        raise "Cannot compare #{self.class} with #{o.class}" unless o.is_a?(self.class)
        o.var == self.var
      end
      alias_method :==, :eql?
    end
  end

end #Stanza
end #Blather
