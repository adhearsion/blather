module Blather
class Stanza

  ##
  # Base Iq stanza
  class Iq < Stanza
    register :iq

    def self.import(node)
      raise(ArgumentError, "Import missmatch #{[node.element_name, self.name].inspect}") if node.element_name != self.name.to_s
      klass = nil
      node.children.each { |e| break if klass = class_from_registration(e.element_name, e.namespace) }
      (klass || self).new(node.attributes[:type]).inherit(node)
    end

    def initialize(type = nil, to = nil, id = nil)
      super :iq
      self.type = type || :get
      self.to = to
      self.id = id if id
    end
  end

end #Stanza
end
