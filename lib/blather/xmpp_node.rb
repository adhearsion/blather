module Blather

  # Base XML Node
  # All XML classes subclass XMPPNode it allows the addition of helpers
  class XMPPNode < Niceogiri::XML::Node
    # @private
    BASE_NAMES = %w[presence message iq].freeze

    # @private
    @@registrations = {}

    class_attribute :registered_ns, :registered_name

    # Register a new stanza class to a name and/or namespace
    #
    # This registers a namespace that is used when looking
    # up the class name of the object to instantiate when a new
    # stanza is received
    #
    # @param [#to_s] name the name of the node
    # @param [String, nil] ns the namespace the node belongs to
    def self.register(name, ns = nil)
      self.registered_name = name.to_s
      self.registered_ns = ns
      @@registrations[[self.registered_name, self.registered_ns]] = self
    end

    # Find the class to use given the name and namespace of a stanza
    #
    # @param [#to_s] name the name to lookup
    # @param [String, nil] xmlns the namespace the node belongs to
    # @return [Class, nil] the class appropriate for the name/ns combination
    def self.class_from_registration(name, ns = nil)
      @@registrations[[name.to_s, ns]]
    end

    # Import an XML::Node to the appropriate class
    #
    # Looks up the class the node should be then creates it based on the
    # elements of the XML::Node
    # @param [XML::Node] node the node to import
    # @return the appropriate object based on the node name and namespace
    def self.import(node)
      ns = (node.namespace.href if node.namespace)
      klass = class_from_registration(node.element_name, ns)
      if klass && klass != self
        klass.import(node)
      else
        new(node.element_name).inherit(node)
      end
    end

    # Create a new Node object
    #
    # @param [String, nil] name the element name
    # @param [XML::Document, nil] doc the document to attach the node to. If
    # not provided one will be created
    # @return a new object with the registered name and namespace
    def self.new(name = registered_name, doc = nil)
      super name, doc, BASE_NAMES.include?(name.to_s) ? nil : self.registered_ns
    end

    # Turn the object into a proper stanza
    #
    # @return a stanza object
    def to_stanza
      self.class.import self
    end
  end  # XMPPNode

end  # Blather
