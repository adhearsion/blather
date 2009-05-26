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
      ns = node.namespace.href if node.namespace
      klass = class_from_registration(node.element_name, ns)
      if klass && klass != self
        klass.import(node)
      else
        new(node.element_name).inherit(node)
      end
    end

    ##
    # Provides an attribute reader helper. Default behavior is to
    # conver the values of the attribute into a symbol. This can
    # be turned off by passing <tt>:to_sym => false</tt>
    #
    #   class Node
    #     attribute_reader :type
    #     attribute_reader :name, :to_sym => false
    #   end
    #
    #   n = Node.new
    #   n[:type] = 'foo'
    #   n.type == :foo
    #   n[:name] = 'bar'
    #   n.name == 'bar'
    def self.attribute_reader(*syms)
      opts = syms.last.is_a?(Hash) ? syms.pop : {}
      convert_str = "val.#{opts[:call]} if val" if opts[:call]
      syms.flatten.each do |sym|
        class_eval(<<-END, __FILE__, __LINE__)
          def #{sym}
            val = self[:#{sym}]
            #{convert_str}
          end
        END
      end
    end

    ##
    # Provides an attribute writer helper.
    #
    #   class Node
    #     attribute_writer :type
    #   end
    #
    #   n = Node.new
    #   n.type = 'foo'
    #   n[:type] == 'foo'
    def self.attribute_writer(*syms)
      syms.flatten.each do |sym|
        next if sym.is_a?(Hash)
        class_eval(<<-END, __FILE__, __LINE__)
          def #{sym}=(value)
            self[:#{sym}] = value
          end
        END
      end
    end

    ##
    # Provides an attribute accessor helper combining
    # <tt>attribute_reader</tt> and <tt>attribute_writer</tt>
    #
    #   class Node
    #     attribute_accessor :type
    #     attribute_accessor :name, :to_sym => false
    #   end
    #
    #   n = Node.new
    #   n.type = 'foo'
    #   n.type == :foo
    #   n.name = 'bar'
    #   n.name == 'bar'
    def self.attribute_accessor(*syms)
      attribute_reader *syms
      attribute_writer *syms
    end

    ##
    # Provides a content reader helper that returns the content of a node
    # +method+ is the method to create
    # +conversion+ is a method to call on the content before sending it back
    # +node+ is the name of the content node (this defaults to the method name)
    #
    #   class Node
    #     content_attr_reader :body
    #     content_attr_reader :type, :to_sym
    #     content_attr_reader :id, :to_i, :identity
    #   end
    #
    #   n = Node.new 'foo'
    #   n.to_s == "<foo><body>foobarbaz</body><type>error</type><identity>1000</identity></foo>"
    #   n.body == 'foobarbaz'
    #   n.type == :error
    #   n.id == 1000
    def self.content_attr_reader(method, conversion = nil, node = nil)
      node ||= method
      conversion = "val.#{conversion} if val.respond_to?(:#{conversion})" if conversion
      class_eval(<<-END, __FILE__, __LINE__)
        def #{method}
          val = content_from :#{node}
          #{conversion}
        end
      END
    end

    ##
    # Provides a content writer helper that creates or updates the content of a node
    # +method+ is the method to create
    # +node+ is the name of the node to create (defaults to the method name)
    #
    #   class Node
    #     content_attr_writer :body
    #     content_attr_writer :id, :identity
    #   end
    #
    #   n = Node.new 'foo'
    #   n.body = 'thebodytext'
    #   n.id = 'id-text'
    #   n.to_s == '<foo><body>thebodytext</body><identity>id-text</identity></foo>'
    def self.content_attr_writer(method, node = nil)
      node ||= method
      class_eval(<<-END, __FILE__, __LINE__)
        def #{method}=(val)
          set_content_for :#{node}, val
        end
      END
    end

    ##
    # Provides a quick way of building +content_attr_reader+ and +content_attr_writer+
    # for the same method and node
    def self.content_attr_accessor(method, conversion = nil, node = nil)
      content_attr_reader method, conversion, node
      content_attr_writer method, node
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
      inherit_attrs stanza.attributes
      stanza.children.each do |c|
        self << (child = c.dup)
        child.document = self.document
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
