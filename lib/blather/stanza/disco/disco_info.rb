module Blather
class Stanza

  ##
  # DiscoInfo object ()
  # 
  class DiscoInfo < Disco
    register :disco_info, nil, 'http://jabber.org/protocol/disco#info'

    def initialize(type = nil, node = nil, identities = [], features = [])
      super type

      self.node = node

      [identities].flatten.each do |id|
        query << (id.is_a?(Identity) ? id : Identity.new(id[:name], id[:type], id[:category]))
      end

      [features].flatten.each do |feature|
        query << (feature.is_a?(Feature) ? feature : Feature.new(feature))
      end
    end

    ##
    # List of identity objects
    def identities
      identities = query.find('identity')
      identities = query.find('query_ns:identity', :query_ns => self.class.ns) if identities.empty?
      identities.map { |i| Identity.new i }
    end

    ##
    # List of feature objects
    def features
     features = query.find('feature')
     features = query.find('query_ns:feature', :query_ns => self.class.ns) if features.empty?
     features.map { |i| Feature.new i }
    end

    class Identity < XMPPNode
      attribute_accessor :category, :type
      attribute_accessor :name, :to_sym => false

      def initialize(name, type = nil, category = nil)
        super :identity

        if name.is_a?(XML::Node)
          self.inherit name
        else
          self.name = name
          self.type = type
          self.category = category
        end
      end

      def eql?(other)
        other.kind_of?(self.class) &&
        other.name == self.name &&
        other.type == self.type &&
        other.category == self.category
      end
    end

    class Feature < XMPPNode
      attribute_accessor :var, :to_sym => false

      def initialize(var)
        super :feature
        if var.is_a?(XML::Node)
          self.inherit var
        else
          self.var = var
        end
      end

      def eql?(other)
        other.kind_of?(self.class) &&
        other.var == self.var
      end
    end
  end

end #Stanza
end #Blather
