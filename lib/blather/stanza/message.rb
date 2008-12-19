module Blather
class Stanza

  ##
  # Base Message stanza
  class Message < Stanza
    VALID_TYPES = [:chat, :error, :groupchat, :headline, :normal]

    register :message

    def self.new(to = nil, body = nil, type = :chat)
      elem = super()
      elem.to = to
      elem.type = type
      elem.body = body
      elem
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

    def body=(body)
      remove_child :body
      self << XMPPNode.new('body', body) if body
    end

    def body
      content_from :body
    end

    def subject=(subject)
      remove_child :subject
      self << XMPPNode.new('subject', subject) if subject
    end

    def subject
      content_from :subject
    end

    def thread=(thread)
      remove_child :thread
      self << XMPPNode.new('body', body) if body
    end

    def thread
      content_from :thread
    end
  end

end #Stanza
end