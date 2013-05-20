module Blather

  # Base XML Node
  # All XML classes subclass XMPPNode it allows the addition of helpers
  class XMPPNode < Nokogiri::XML::Node
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
    def self.import(node, *decorators)
      ns = (node.namespace.href if node.namespace)
      klass = class_from_registration(node.node_name, ns)
      if klass && klass != self
        klass.import(node, *decorators)
      else
        new(node.node_name).decorate(*decorators).inherit(node)
      end
    end

    # Parse a string as XML and import to the appropriate class
    #
    # @param [String] string the string to parse
    # @return the appropriate object based on the node name and namespace
    def self.parse(string)
      import Nokogiri::XML(string).root
    end

    # Create a new Node object
    #
    # @param [String, nil] name the element name
    # @param [XML::Document, nil] doc the document to attach the node to. If
    # not provided one will be created
    # @return a new object with the registered name and namespace
    def self.new(name = registered_name, doc = nil)
      super(name.to_s, (doc || Nokogiri::XML::Document.new)).tap do |node|
        node.document.root = node unless doc
        ns = BASE_NAMES.include?(name.to_s) ? nil : self.registered_ns
        node.namespace = ns if ns
      end
    end

    def self.decorator_modules
      if self.const_defined?(:InstanceMethods)
        [self::InstanceMethods]
      else
        []
      end
    end

    def decorate(*decorators)
      decorators.each do |decorator|
        decorator.decorator_modules.each do |mod|
          extend mod
        end

        @handler_hierarchy.unshift decorator.handler_hierarchy.first if decorator.respond_to?(:handler_hierarchy)
      end
      self
    end

    # Helper method to read an attribute
    #
    # @param [#to_sym] attr_name the name of the attribute
    # @param [String, Symbol, nil] to_call the name of the method to call on
    # the returned value
    # @return nil or the value
    def read_attr(attr_name, to_call = nil)
      val = self[attr_name]
      val && to_call ? val.__send__(to_call) : val
    end

    # Helper method to write a value to an attribute
    #
    # @param [#to_sym] attr_name the name of the attribute
    # @param [#to_s] value the value to set the attribute to
    def write_attr(attr_name, value, to_call = nil)
      self[attr_name] = value && to_call ? value.__send__(to_call) : value
    end

    # Helper method to read the content of a node
    #
    # @param [#to_sym] node the name of the node
    # @param [String, Symbol, nil] to_call the name of the method to call on
    # the returned value
    # @return nil or the value
    def read_content(node, to_call = nil)
      val = content_from node.to_sym
      val && to_call ? val.__send__(to_call) : val
    end

    # @private
    alias_method :nokogiri_namespace=, :namespace=
    # Attach a namespace to the node
    #
    # @overload namespace=(ns)
    #   Attach an already created XML::Namespace
    #   @param [XML::Namespace] ns the namespace object
    # @overload namespace=(ns)
    #   Create a new namespace and attach it
    #   @param [String] ns the namespace uri
    # @overload namespace=(namespaces)
    #   Createa and add new namespaces from a hash
    #   @param [Hash] namespaces a hash of prefix => uri pairs
    def namespace=(namespaces)
      case namespaces
      when Nokogiri::XML::Namespace
        self.nokogiri_namespace = namespaces
      when String
        ns = self.add_namespace nil, namespaces
        self.nokogiri_namespace = ns
      when Hash
        self.add_namespace nil, ns if ns = namespaces.delete(nil)
        namespaces.each do |p, n|
          ns = self.add_namespace p, n
          self.nokogiri_namespace = ns
        end
      end
    end

    # Helper method to get the node's namespace
    #
    # @return [XML::Namespace, nil] The node's namespace object if it exists
    def namespace_href
      namespace.href if namespace
    end

    # Remove a child with the name and (optionally) namespace given
    #
    # @param [String] name the name or xpath of the node to remove
    # @param [String, nil] ns the namespace the node is in
    def remove_child(name, ns = nil)
      child = xpath(name, ns).first
      child.remove if child
    end

    # Remove all children with a given name regardless of namespace
    #
    # @param [String] name the name of the nodes to remove
    def remove_children(name)
      xpath("./*[local-name()='#{name}']").remove
    end

    # The content of the named node
    #
    # @param [String] name the name or xpath of the node
    # @param [String, nil] ns the namespace the node is in
    # @return [String, nil] the content of the node
    def content_from(name, ns = nil)
      child = xpath(name, ns).first
      child.content if child
    end

    # Sets the content for the specified node.
    # If the node exists it is updated. If not a new node is created
    # If the node exists and the content is nil, the node will be removed
    # entirely
    #
    # @param [String] node the name of the node to update/create
    # @param [String, nil] content the content to set within the node
    def set_content_for(node, content = nil)
      if content
        child = xpath(node).first
        self << (child = XMPPNode.new(node, self.document)) unless child
        child.content = content
      else
        remove_child node
      end
    end

    alias_method :copy, :dup

    # Inherit the attributes and children of an XML::Node
    #
    # @param [XML::Node] node the node to inherit
    # @return [self]
    def inherit(node)
      inherit_namespaces node
      inherit_attrs node.attributes
      inherit_children node
      self
    end

    def inherit_namespaces(node)
      node.namespace_definitions.each do |ns|
        add_namespace ns.prefix, ns.href
      end
      self.namespace = node.namespace.href if node.namespace
    end

    # Inherit a set of attributes
    #
    # @param [Hash] attrs a hash of attributes to set on the node
    # @return [self]
    def inherit_attrs(attrs)
      attrs.each do |name, value|
        attr_name = value.namespace && value.namespace.prefix ? [value.namespace.prefix, name].join(':') : name
        self.write_attr attr_name, value
      end
      self
    end

    def inherit_children(node)
      node.children.each do |c|
        self << (n = c.dup)
        if c.respond_to?(:namespace) && c.namespace
          ns = n.add_namespace c.namespace.prefix, c.namespace.href
          n.namespace = ns
        end
      end
    end

    # The node as XML
    #
    # @return [String] XML representation of the node
    def inspect
      self.to_xml
    end

    # Check that a set of fields are equal between nodes
    #
    # @param [Node] other the other node to compare against
    # @param [*#to_s] fields the set of fields to compare
    # @return [Fixnum<-1,0,1>]
    def eql?(o, *fields)
      o.is_a?(self.class) && fields.all? { |f| self.__send__(f) == o.__send__(f) }
    end

    # @private
    def ==(o)
      eql?(o)
    end

    # Turn the object into a proper stanza
    #
    # @return a stanza object
    def to_stanza
      self.class.import self
    end
  end  # XMPPNode

end  # Blather
