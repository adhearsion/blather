module Blather
class Stanza

  class Message < Stanza
    register :message

    def self.generate_thread_id
      Digest::MD5.hexdigest(Time.new.to_f.to_s)
    end

    def self.new(to = nil, type = nil, body = nil)
      elem = super()
      elem.to = to
      elem.type = type
      elem.body = body
      elem
    end

    VALID_TYPES = [:chat, :error, :groupchat, :headline, :normal]
    def type=(type)
      raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}" if type && !VALID_TYPES.include?(type.to_sym)
      super
    end

    def body=(body)
      remove_child :body
      self << XML::Node.new('body', body) if body
    end

    def body
      content_from :body
    end

    def subject=(subject)
      remove_child :subject
      self << XML::Node.new('subject', subject) if subject
    end

    def subject
      content_from :subject
    end

    def thread=(thread)
      remove_child :thread
      self << XML::Node.new('body', body) if body
    end

    def thread
      content_from :thread
    end
  end

end #Stanza
end