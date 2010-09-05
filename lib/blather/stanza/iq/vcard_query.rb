module Blather
class Stanza
class Iq

  # # VcardQuery Stanza
  #
  # [XEP-0054 vcard-temp](http://xmpp.org/extensions/xep-0054.html)
  #
  # This is a base class for any vcard based Iq stanzas. It provides a base set
  # of methods for working with vcard stanzas
  #
  # @example Retrieving One's vCard
  #     iq = Blather::Stanza::Iq::VcardQuery.new :get
  #     client.write_with_handler iq do |response|
  #       puts response.vcard
  #     end
  #
  # @example Updating One's vCard
  #     iq = Blather::Stanza::Iq::VcardQuery.new :set
  #     iq.vcard['NICKNAME'] = 'Romeo'
  #     client.write_with_handler iq do |response|
  #       puts response
  #     end
  #
  # @example Viewing Another User's vCard
  #     iq = Blather::Stanza::Iq::VcardQuery.new :get, 'mercutio@example.org'
  #     client.write_with_handler iq do |response|
  #       puts response.vcard
  #     end
  #
  # @handler :vcard_query
  class VcardQuery < Iq

    register :vcard_query, :vCard, 'vcard-temp'

    # Overrides the parent method to ensure a vcard node is created
    #
    # @see Blather::Stanza::Iq.new
    def self.new(type = nil, to = nil, id = nil)
      node = super
      node.vcard
      node
    end

    # Overrides the parent method to ensure the current vcard node is destroyed
    #
    # @see Blather::Stanza::Iq#inherit
    def inherit(node)
      vcard.remove
      super
      self
    end

    # Find or create vcard node
    #
    # @return [VcardQuery::Vcard]
    def vcard
      Vcard.find_or_create self
    end

    # Replaces vcard node
    #
    # @param [VcardQuery::Vcard, XML::Node] info the stanza's new vcard node
    #
    # @return [VcardQuery::Vcard]
    def vcard=(info)
      vcard.remove
      self << info
      Vcard.find_or_create self
    end

    class Vcard < XMPPNode

      VCARD_NS = 'vcard-temp'

      # Create a new VcardQuery::Vcard object
      #
      # @param [XML::Node, nil] node a node to inherit from
      #
      # @return [VcardQuery::Vcard]
      def self.new(node = nil)
        new_node = super :vCard
        new_node.namespace = VCARD_NS
        new_node.inherit node if node
        new_node
      end

      # Find or create vCard node in VcardQuery Iq and converts it to VcardQuery::Vcard
      #
      # @param [VcardQuery] parent a VcardQuery Iq where to find or create vCard
      #
      # @return [VcardQuery::Vcard]
      def self.find_or_create(parent)
        if found_vcard = parent.find_first('//ns:vCard', :ns => VCARD_NS)
          vcard = self.new found_vcard
          found_vcard.remove
        else
          vcard = self.new
        end
        parent << vcard

        vcard
      end

      # Find the element's value by name
      #
      # @param [String] name the name of the element
      #
      # @return [String, nil]
      def [](name)
        name = name.split("/").map{|child| "ns:#{child}"}.join("/")

        if elem = find_first(name, :ns => VCARD_NS)
          elem.content
        else
          nil
        end
      end

      # Set the element's value
      #
      # @param [String] name the name of the element
      # @param [String, nil] value the new value of element
      #
      # @return [String, nil]
      def []=(name, value)
        elem = nil
        parent = self

        name.split("/").each do |child|
          elem = parent.find_first("ns:#{child}", :ns => VCARD_NS)
          unless elem
            elem = XMPPNode.new(child, parent.document)
            parent << elem
            parent = elem
          else
            parent = elem
          end
        end

        elem.content = value
      end
    end
  end
end
end
end