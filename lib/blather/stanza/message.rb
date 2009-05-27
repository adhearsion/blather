module Blather
class Stanza

  ##
  # Base Message stanza
  class Message < Stanza
    VALID_TYPES = [:chat, :error, :groupchat, :headline, :normal]

    register :message

    def self.import(node)
      klass = nil
      node.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }

      if klass && klass != self
        klass.import(node)
      else
        new(node[:type]).inherit(node)
      end
    end

    def self.new(to = nil, body = nil, type = :chat)
      node = super(:message)
      node.to = to
      node.type = type
      node.body = body
      node
    end

    VALID_TYPES.each do |valid_type|
      define_method("#{valid_type}?") { self.type == valid_type }
    end

    ##
    # Ensures type is :chat, :error, :groupchat, :headline or :normal
    def type=(type)
      raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}" if type && !VALID_TYPES.include?(type.to_sym)
      super
    end

    content_attr_accessor :body
    content_attr_accessor :subject
    content_attr_accessor :thread
  end

end #Stanza
end