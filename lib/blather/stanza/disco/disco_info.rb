module Blather
class Stanza

  # # DiscoInfo Stanza
  #
  # [XEP-0030 Disco Info](http://xmpp.org/extensions/xep-0030.html#info)
  #
  # Disco Info node that provides or retreives information about a jabber entity
  #
  # @handler :disco_info
  class DiscoInfo < Disco
    register :disco_info, nil, 'http://jabber.org/protocol/disco#info'

    # Create a new DiscoInfo stanza
    # @param [:get, :set, :result, :error, nil] type the Iq stanza type
    # @param [String, nil] node the name of the node the info belongs to
    # @param [Array<Array, DiscoInfo::Identity>, nil] identities a list of
    # identities. these are passed directly to DiscoInfo::Identity.new
    # @param [Array<Array, DiscoInfo::Identity>, nil] features a list of
    # features. these are passed directly to DiscoInfo::Feature.new
    # @return [DiscoInfo] a new DiscoInfo stanza
    def self.new(type = nil, node = nil, identities = [], features = [])
      new_node = super type
      new_node.node = node
      new_node.identities = [identities]
      new_node.features = [features]
      new_node
    end

    # List of identity objects
    def identities
      query.find('//ns:identity', :ns => self.class.registered_ns).map do |i|
        Identity.new i
      end
    end

    # Add an array of identities
    # @param identities the array of identities, passed directly to Identity.new
    def identities=(identities)
      [identities].flatten.each { |i| self.query << Identity.new(i) }
    end

    # List of feature objects
    def features
      query.find('//ns:feature', :ns => self.class.registered_ns).map do |f|
        Feature.new f
      end
    end

    # Add an array of features
    # @param features the array of features, passed directly to Feature.new
    def features=(features)
      [features].flatten.each { |f| self.query << Feature.new(f) }
    end

    class Identity < XMPPNode
      # Create a new DiscoInfo Identity
      # @overload new(node)
      #   Imports the XML::Node to create a Identity object
      #   @param [XML::Node] node the node object to import
      # @overload new(opts = {})
      #   Creates a new Identity using a hash of options
      #   @param [Hash] opts a hash of options
      #   @option opts [String] :name the name of the identity
      #   @option opts [String] :type the type of the identity
      #   @option opts [String] :category the category of the identity
      # @overload new(name, type = nil, category = nil)
      #   Create a new Identity by name
      #   @param [String] name the name of the Identity
      #   @param [String, nil] type the type of the Identity
      #   @param [String, nil] category the category of the Identity
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

      # The Identity's category
      # @return [Symbol, nil]
      def category
        read_attr :category, :to_sym
      end

      # Set the Identity's category
      # @param [String, Symbol] category the new category
      def category=(category)
        write_attr :category, category
      end

      # The Identity's type
      # @return [Symbol, nil]
      def type
        read_attr :type, :to_sym
      end

      # Set the Identity's type
      # @param [String, Symbol] type the new category
      def type=(type)
        write_attr :type, type
      end

      # The Identity's name
      # @return [String]
      def name
        read_attr :name
      end

      # Set the Identity's name
      # @param [String] name the new name for the identity
      def name=(name)
        write_attr :name, name
      end

      # Compare two Identity objects by name, type and category
      # @param [DiscoInfo::Identity] o the Identity object to compare against
      # @return [true, false]
      def eql?(o)
        unless o.is_a?(self.class)
          raise "Cannot compare #{self.class} with #{o.class}"
        end

        o.name == self.name &&
        o.type == self.type &&
        o.category == self.category
      end
      alias_method :==, :eql?
    end # Identity

    class Feature < XMPPNode
      # Create a new DiscoInfo::Feature object
      # @overload new(node)
      #   Create a new Feature by importing an XML::Node
      #   @param [XML::Node] node an XML::Node to import
      # @overload new(var)
      #   Create a new feature by var
      #   @param [String] var a the Feautre's var
      # @return [DiscoInfo::Feature]
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

      # The Feature's var
      # @return [String]
      def var
        read_attr :var
      end

      # Set the Feature's var
      # @param [String] var the new var
      def var=(var)
        write_attr :var, var
      end

      # Compare two Feature objects by var
      # @param [DiscoInfo::Feature] o the Feature object to compare against
      # @return [true, false]
      def eql?(o)
        unless o.is_a?(self.class)
          raise "Cannot compare #{self.class} with #{o.class}"
        end

        o.var == self.var
      end
      alias_method :==, :eql?
    end
  end # Feature

end # Stanza
end # Blather
