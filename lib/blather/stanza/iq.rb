module Blather
class Stanza

  ##
  # Base Iq stanza
  class Iq < Stanza
    register :iq

    def self.import(node)
      raise "Import missmatch #{[node.element_name, self.name].inspect}" if node.element_name != self.name.to_s
      klass = nil
      node.each { |e| break if klass = class_from_registration(e.element_name, e.xmlns) }
      (klass || self).new(node['type']).inherit(node)
    end

    def self.new(type = :get, to = nil, id = nil)
      elem = super :iq
      elem.xmlns = nil
      elem.type = type
      elem.to = to
      elem.id = id if id
      elem
    end
  end

end #Stanza
end
