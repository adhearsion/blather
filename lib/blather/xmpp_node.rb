module Blather

  ##
  # Base XML Node
  # All XML classes subclass XMPPNode
  # it allows the addition of helpers
  class XMPPNode < XML::Node
    BASE_NAMES = %w[presence message iq].freeze

    @@registrations = {}

    class_inheritable_accessor  :ns,
                                :name

    ##
    # Lets a subclass register itself
    #
    # This registers a namespace that is used when looking
    # up the class name of the object to instantiate when a new
    # stanza is received
    def self.register(name, ns = nil)
      self.name = name.to_s
      self.ns = ns
      @@registrations[[self.name, self.ns]] = self
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
      klass = class_from_registration(node.element_name, node.namespace)
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
    #   n.attributes[:type] = 'foo'
    #   n.type == :foo
    #   n.attributes[:name] = 'bar'
    #   n.name == 'bar'
    def self.attribute_reader(*syms)
      opts = syms.last.is_a?(Hash) ? syms.pop : {}
      syms.flatten.each do |sym|
        class_eval(<<-END, __FILE__, __LINE__)
          def #{sym}
            attributes[:#{sym}]#{".to_sym unless attributes[:#{sym}].blank?" unless opts[:to_sym] == false}
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
    #   n.attributes[:type] == 'foo'
    def self.attribute_writer(*syms)
      syms.flatten.each do |sym|
        next if sym.is_a?(Hash)
        class_eval(<<-END, __FILE__, __LINE__)
          def #{sym}=(value)
            attributes[:#{sym}] = value
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
    # Automatically sets the namespace registered by the subclass
    def initialize(name = nil, content = nil)
      name ||= self.class.name
      content = content.to_s if content

      super name.to_s, content
      self.namespace = self.class.ns unless BASE_NAMES.include?(name.to_s)
    end

    ##
    # Quickway of turning itself into a proper object
    def to_stanza
      self.class.import self
    end

    def namespace=(ns)
      if ns
        ns = {nil => ns} unless ns.is_a?(Hash)
        ns.each { |p,n| XML::Namespace.new self, p, n }
      end
    end

    def namespace(prefix = nil)
      (ns = namespaces.find_by_prefix(prefix)) ? ns.href : nil
    end

    ##
    # Remove a child with the name and (optionally) namespace given
    def remove_child(name, ns = nil)
      name = name.to_s
      self.detect { |n| n.remove! if n.element_name == name && (!ns || n.namespace == ns) }
    end

    ##
    # Remove all children with a given name
    def remove_children(name)
      name = name.to_s
      self.find(name).each { |n| n.remove! }
    end

    ##
    # Pull the content from a child
    def content_from(name)
      name = name.to_s
      (child = self.detect { |n| n.element_name == name }) ? child.content : nil
    end

    ##
    # Create a copy
    def copy(deep = true)
      self.class.new(self.element_name).inherit(self)
    end

    ##
    # Inherit all of <tt>stanza</tt>'s attributes and children
    def inherit(stanza)
      inherit_attrs stanza.attributes
      stanza.children.each { |c| self << c.copy(true) }
      self
    end

    ##
    # Inherit only <tt>stanza</tt>'s attributes
    def inherit_attrs(attrs)
      attrs.each  { |a| attributes[a.name] = a.value }
      self
    end

    ##
    # Turn itself into an XML string and remove all whitespace between nodes
    def to_xml
      # TODO: Fix this for HTML nodes (and any other that might require whitespace)
      to_s.gsub(">\n<", '><')
    end

    ##
    # Override #find to work when a node isn't attached to a document
    def find(what, nslist = nil)
      what = what.to_s
      (self.doc ? super(what, nslist) : select { |i| i.element_name == what })
    end
  end #XMPPNode

end