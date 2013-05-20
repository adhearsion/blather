module Blather
class Stanza
class Presence

  # # Entity Capabilities Stanza
  #
  # [XEP-0115 - Entity Capabilities](http://http://xmpp.org/extensions/xep-0115.html)
  #
  # Blather handles c nodes through this class. It provides a set of helper methods
  # to quickly deal with capabilites presence stanzas.
  #
  # @handler :c
  class C < Presence
    register :c, :c, 'http://jabber.org/protocol/caps'

    # @private
    VALID_HASH_TYPES = %w[md2 md5 sha-1 sha-224 sha-256 sha-384 sha-512].freeze

    def self.new(node = nil, ver = nil, hash = 'sha-1')
      new_node = super()
      new_node.c
      new_node.hash = hash
      new_node.node = node
      new_node.ver = ver
      parse new_node.to_xml
    end

    module InstanceMethods

      # @private
      def inherit(node)
        c.remove
        super
        self
      end

      # Get the name of the node
      #
      # @return [String, nil]
      def node
        c[:node]
      end

      # Set the name of the node
      #
      # @param [String, nil] node the new node name
      def node=(node)
        c[:node] = node
      end

      # Get the name of the hash
      #
      # @return [Symbol, nil]
      def hash
        c[:hash] && c[:hash].to_sym
      end

      # Set the name of the hash
      #
      # @param [String, nil] hash the new hash name
      def hash=(hash)
        if hash && !VALID_HASH_TYPES.include?(hash.to_s)
          raise ArgumentError, "Invalid Hash Type (#{hash}), use: #{VALID_HASH_TYPES*' '}"
        end
        c[:hash] = hash
      end

      # Get the ver
      #
      # @return [String, nil]
      def ver
        c[:ver]
      end

      # Set the ver
      #
      # @param [String, nil] ver the new ver
      def ver=(ver)
        c[:ver] = ver
      end

      # C node accessor
      # If a c node exists it will be returned.
      # Otherwise a new node will be created and returned
      #
      # @return [Blather::XMPPNode]
      def c
        unless c = at_xpath('ns:c', :ns => C.registered_ns)
          self << (c = XMPPNode.new('c', self.document))
          c.namespace = self.class.registered_ns
        end
        c
      end
    end

    include InstanceMethods
  end # C
end #Presence
end #Stanza
end
