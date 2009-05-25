module Blather
class Stanza

  ##
  # Base Message stanza
  class Message < Stanza
    VALID_TYPES = [:chat, :error, :groupchat, :headline, :normal]

    register :message

    def self.new(to = nil, body = nil, type = :chat)
      node = super()
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