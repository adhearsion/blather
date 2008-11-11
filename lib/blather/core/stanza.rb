module Blather
  class Stanza < XMPPNode
    @@registered_callbacks = []

    def self.registered_callbacks
      @@registered_callbacks
    end

    class_inheritable_array :callback_heirarchy

    def self.register(callback_type, name = nil, xmlns = nil)
      @@registered_callbacks << callback_type

      self.callback_heirarchy ||= []
      self.callback_heirarchy.unshift callback_type

      name = name || self.name || callback_type
      super name, xmlns
    end

    def self.next_id
      @@last_id ||= 0
      @@last_id += 1
      'blather%04x' % @@last_id
    end

    def self.import(node)
      self.new(node.element_name).inherit(node)
    end

    def self.new(elem_name = nil)
      elem = super
      elem.id = next_id
      XML::Document.new.root = elem
      elem
    end

    def error?
      self.type == :error
    end

    def reply
      elem = self.copy(true)
      elem.to, elem.from = self.from, self.to
      elem
    end

    def reply!
      self.to, self.from = self.from, self.to
      self
    end

    def id=(id)
      attributes.remove :id
      self['id'] = id if id
    end

    def id
      self['id']
    end

    def to=(to)
      attributes.remove :to
      self['to'] = to.to_s if to
    end

    def to
      JID.new(self['to']) if self['to']
    end

    def from=(from)
      attributes.remove :from
      self['from'] = from.to_s if from
    end

    def from
      JID.new(self['from']) if self['from']
    end

    def type=(type)
      attributes.remove :type
      self['type'] = type.to_s
    end

    def type
      self['type'].to_sym if self['type']
    end

  end
end