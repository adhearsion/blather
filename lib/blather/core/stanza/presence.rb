module Blather
class Stanza

  class Presence < Stanza
    register :presence

    def self.import(node)
      klass = case node['type']
      when nil, 'unavailable' then Status
      when /subscribe/        then Subscription
      else self
      end
      klass.new.inherit(node)
    end

    VALID_TYPES = [:unavailable, :subscribe, :subscribed, :unsubscribe, :unsubscribed, :probe, :error].freeze
    def type=(type)
      raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}" if type && !VALID_TYPES.include?(type.to_sym)
      super
    end

  end

end #Stanza
end