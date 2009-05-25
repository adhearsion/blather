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
      attribute_accessor :category, :type, :call => :to_sym
      attribute_accessor :name

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

      def eql?(o)
        raise "Cannot compare #{self.class} with #{o.class}" unless o.is_a?(self.class)
        o.name == self.name &&
        o.type == self.type &&
        o.category == self.category
      end
      alias_method :==, :eql?
    end

    class Feature < XMPPNode
      attribute_accessor :var

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

      def eql?(o)
        raise "Cannot compare #{self.class} with #{o.class}" unless o.is_a?(self.class)
        o.var == self.var
      end
      alias_method :==, :eql?
    end
  end

end #Stanza
end #Blather
