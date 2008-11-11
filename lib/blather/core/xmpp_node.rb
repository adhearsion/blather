module Blather

  class XMPPNode < XML::Node
    @@registrations = {}

    alias_method :element_name, :name

    class_inheritable_accessor  :xmlns,
                                :name

    def self.new(name = nil, content = nil)
      name ||= self.name

      args = []
      args << name.to_s if name
      args << content if content

      elem = super *args
      elem.xmlns = xmlns
      elem
    end

    def self.register(name, xmlns = nil)
      self.name = name
      self.xmlns = xmlns
      @@registrations[[name, xmlns]] = self
    end

    def self.class_from_registration(name, xmlns)
      name = name.to_sym
      @@registrations[[name, xmlns]] || @@registrations[[name, nil]]
    end

    def self.import(node)
      klass = class_from_registration(node.element_name, node.xmlns)
      node = klass.import(node) if klass
      node
    end

    def to_stanza
      self.class.import self
    end

    def xmlns=(ns)
      attributes.remove :xmlns
      self['xmlns'] = ns if ns
    end

    def xmlns
      self['xmlns']
    end

    def remove_child(name, ns = nil)
      name = name.to_s
      self.each { |n| n.remove! or break if n.element_name == name && (!ns || n.xmlns == ns) }
    end

    def remove_children(name)
      remove_child name, true
    end

    def content_from(name)
      name = name.to_s
      (child = self.detect { |n| n.element_name == name }) ? child.content : nil
    end

    def copy(deep)
      elem = self.class.new(self.element_name)
      elem.inherit self
      elem
    end

    def inherit(stanza)
      inherit_attrs stanza.attributes
      stanza.children.each    { |c| self << c.copy(true) }
      self
    end

    def inherit_attrs(attrs)
      attrs.each  { |a| self[a.name] = a.value }
      self
    end

    def inherit_xml(xml)
      inherit_attrs xml.attributes
      xml.each { |c| self << XMPPNode.new_from_xml(c) }
      self
    end

    def to_s
      super.gsub(">\n<", '><')
    end
  end #XMPPNode

end