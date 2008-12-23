module Blather

  ##
  # Base XML Node
  # All XML classes subclass XMPPNode
  # it allows the addition of helpers
  class XMPPNode < XML::Node
    @@registrations = {}

    class_inheritable_accessor  :xmlns,
                                :name

    ##
    # Lets a subclass register itself
    #
    # This registers a namespace that is used when looking
    # up the class name of the object to instantiate when a new
    # stanza is received
    def self.register(name, xmlns = nil)
      self.name = name.to_s
      self.xmlns = xmlns
      @@registrations[[self.name, self.xmlns]] = self
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
      klass = class_from_registration(node.element_name, node.xmlns)
      if klass && klass != self
        klass.import(node)
      else
        new(node.element_name).inherit(node)
      end
    end

    ##
    # Automatically sets the namespace registered by the subclass
    def initialize(name = nil, content = nil)
      name ||= self.class.name
      content = content.to_s if content

      super name.to_s, content
      self.xmlns = self.class.xmlns
    end

    ##
    # Quickway of turning itself into a proper object
    def to_stanza
      self.class.import self
    end

    def xmlns=(ns)
      attributes[:xmlns] = ns
    end

    def xmlns
      attributes[:xmlns]
    end

    ##
    # Remove a child with the name and (optionally) namespace given
    def remove_child(name, ns = nil)
      name = name.to_s
      self.each { |n| n.remove! if n.element_name == name && (!ns || n.xmlns == ns) }
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
    # Turn itself into a string and remove all whitespace between nodes
    def to_s
      # TODO: Fix this for HTML nodes (and any other that might require whitespace)
      super.gsub(">\n<", '><')
    end

    ##
    # Override #find to work when a node isn't attached to a document
    def find(what, nslist = nil)
      what = what.to_s
      (self.doc ? super(what, nslist) : select { |i| i.element_name == what })
    end
  end #XMPPNode

end