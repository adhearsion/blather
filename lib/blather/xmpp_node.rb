module Blather

  ##
  # Base XML Node
  # All XML classes subclass XMPPNode
  # it allows the addition of helpers
  class XMPPNode < Nokogiri::XML::Node
    BASE_NAMES = %w[presence message iq].freeze

    @@registrations = {}

    class_inheritable_accessor  :registered_ns,
                                :registered_name

    ##
    # Lets a subclass register itself
    #
    # This registers a namespace that is used when looking
    # up the class name of the object to instantiate when a new
    # stanza is received
    def self.register(name, ns = nil)
      self.registered_name = name.to_s
      self.registered_ns = ns
      @@registrations[[self.registered_name, self.registered_ns]] = self
    end

    ##
    # Find the class to use given the name and namespace of a stanza
    def self.class_from_registration(name, xmlns)
      name = name.to_s
      @@registrations[[name, xmlns]] || @@registrations[[name, nil]]
    end

    ##
    # Looks up the class to use then instantiates an object
    # of that class and imports all the <tt>node</tt>'s attributes
    # and children into it.
    def self.import(node)
      klass = class_from_registration(node.element_name, (node.namespace.href if node.namespace))
      if klass && klass != self
        klass.import(node)
      else
        new(node.element_name).inherit(node)
      end
    end

    ##
    # Automatically sets the namespace registered by the subclass
    def self.new(name = nil, doc = nil)
      name ||= self.registered_name

      node = super name.to_s, (doc || Nokogiri::XML::Document.new)
      node.document.root = node unless doc
      node.namespace = self.registered_ns unless BASE_NAMES.include?(name.to_s)
      node
    end

    def read_attr(attr_name, to_call = nil)
      val = self[attr_name.to_sym]
      val && to_call ? val.__send__(to_call) : val
    end

    def write_attr(attr_name, value)
      self[attr_name.to_sym] = value
    end

    def read_content(node, to_call = nil)
      val = content_from node.to_sym
      val && to_call ? val.__send__(to_call) : val
    end

    ##
    # Quickway of turning itself into a proper object
    def to_stanza
      self.class.import self
    end

    alias_method :nokogiri_namespace=, :namespace=
    def namespace=(namespaces)
      case namespaces
      when Nokogiri::XML::Namespace
        self.nokogiri_namespace = namespaces
      when String
        self.add_namespace nil, namespaces
      when Hash
        if ns = namespaces.delete(nil)
          self.add_namespace nil, ns
        end
        namespaces.each do |p, n|
          ns = self.add_namespace p, n
          self.nokogiri_namespace = ns
        end
      end
    end

    def namespace_href
      namespace.href if namespace
    end

    ##
    # Remove a child with the name and (optionally) namespace given
    def remove_child(name, ns = nil)
      child = xpath(name, ns).first
      child.remove if child
    end

    ##
    # Remove all children with a given name
    def remove_children(name)
      xpath("./*[local-name()='#{name}']").remove
    end

    ##
    # Pull the content from a child
    def content_from(name, ns = nil)
      child = xpath(name, ns).first
      child.content if child
    end

    ##
    # Sets the content for the specified node.
    # If the node exists it is updated. If not a new node is created
    # If the node exists and the content is nil, the node will be removed entirely
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

    ##
    # Inherit all of <tt>stanza</tt>'s attributes and children
    def inherit(stanza)
      set_namespace stanza.namespace if stanza.namespace
      inherit_attrs stanza.attributes
      stanza.children.each do |c|
        self << (n = c.dup)
        ns = n.namespace_definitions.find { |ns| ns.prefix == c.namespace.prefix }
        n.namespace = ns if ns
      end
      self
    end

    ##
    # Inherit only <tt>stanza</tt>'s attributes
    def inherit_attrs(attrs)
      attrs.each  { |name, value| self[name] = value }
      self
    end
  end #XMPPNode

end
