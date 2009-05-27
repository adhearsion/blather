module Blather
class Stanza

  ##
  # Base Iq stanza
  class Iq < Stanza
    VALID_TYPES = [:get, :set, :result, :error]

    register :iq

    def self.import(node)
      klass = nil
      node.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }

      if klass && klass != self
        klass.import(node)
      else
        new(node[:type]).inherit(node)
      end
    end

    def self.new(type = nil, to = nil, id = nil)
      node = super :iq
      node.type = type || :get
      node.to = to
      node.id = id || self.next_id
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
