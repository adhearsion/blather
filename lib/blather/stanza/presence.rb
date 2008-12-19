module Blather
class Stanza

  ##
  # Base Presence stanza
  class Presence < Stanza
    VALID_TYPES = [:unavailable, :subscribe, :subscribed, :unsubscribe, :unsubscribed, :probe, :error]

    register :presence

    ##
    # Creates a class based on the presence type
    # either a Status or Subscription object is created based
    # on the type attribute.
    # If neither is found it instantiates a Presence object
    def self.import(node)
      klass = case node['type']
      when nil, 'unavailable' then Status
      when /subscribe/        then Subscription
      else self
      end
      klass.new.inherit(node)
    end

    VALID_TYPES.each do |valid_type|
      define_method("#{valid_type}?") { self.type == valid_type }
    end

    ##
    # Ensures type is one of :unavailable, :subscribe, :subscribed, :unsubscribe, :unsubscribed, :probe or :error
    def type=(type)
      raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}" if type && !VALID_TYPES.include?(type.to_sym)
      super
    end

  end

end #Stanza
end