module Blather
class Stanza

  ##
  # Base Iq stanza
  class Iq < Stanza
    VALID_TYPES = [:get, :set, :result, :error]

    register :iq

    def self.import(node)
      raise(ArgumentError, "Import missmatch #{[node.element_name, self.registered_name].inspect}") if node.element_name != self.registered_name.to_s
      klass = nil
      node.children.each { |e| break if klass = class_from_registration(e.element_name, e.namespace) }
      (klass || self).new(node.attributes[:type]).inherit(node)
    end

    def self.new(type = nil, to = nil, id = nil)
      node = super :iq
      node.type = type || :get
      node.to = to
      node.id = id if id
      node
    end

    VALID_TYPES.each do |valid_type|
      define_method("#{valid_type}?") { self.type == valid_type }
    end

    ##
    # Ensures type is :get, :set, :result or :error
    def type=(type)
      raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}" if type && !VALID_TYPES.include?(type.to_sym)
      super
    end
  end

end #Stanza
end
