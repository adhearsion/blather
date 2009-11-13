module Blather
class Stanza

  # = Iq Stanza
  #
  # Info/Query, or IQ, is a request-response mechanism, similar in some ways to HTTP. The semantics of IQ enable an entity
  # to make a request of, and receive a response from, another entity. The data content of the request and response is
  # defined by the namespace declaration of a direct child element of the IQ element, and the interaction is tracked by the
  # requesting entity through use of the 'id' attribute. Thus, IQ interactions follow a common pattern of structured data
  # exchange such as get/result or set/result (although an error may be returned in reply to a request if appropriate).
  #
  # == ID Attribute
  #
  # Iq Stanzas require the ID attribute be set. Blather will handle this automatically when a new Iq is created.
  #
  # == Type Attribute
  #
  # * +:get+ -- The stanza is a request for information or requirements.
  # * +:set+ -- The stanza provides required data, sets new values, or replaces existing values.
  # * +:result+ -- The stanza is a response to a successful get or set request.
  # * +:error+ -- An error has occurred regarding processing or delivery of a previously-sent get or set (see Stanza Errors).
  #
  # Blather provides a helper for each possible type:
  #
  #   Iq#get?
  #   Iq#set?
  #   Iq#result?
  #   Iq#error?
  #
  # Blather treats the +type+ attribute like a normal ruby object attribute providing a getter and setter.
  # The default +type+ is +get+.
  #
  #   iq = Iq.new
  #   iq.type               # => :get
  #   iq.get?               # => true
  #   iq.type = :set
  #   iq.set?               # => true
  #   iq.get?               # => false
  #
  #   iq.type = :invalid    # => RuntimeError
  #
  class Iq < Stanza
    VALID_TYPES = [:get, :set, :result, :error] # :nodoc:

    register :iq

    def self.import(node) # :nodoc:
      klass = nil
      node.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }

      if klass && klass != self
        klass.import(node)
      else
        new(node[:type]).inherit(node)
      end
    end

    ##
    # Create a new Iq
    # * +type+ - the type of stanza (:get, :set, :result, :error)
    # * +to+ - the JID of the inteded recipient
    # * +id+ - the stanza's ID. Leaving this nil will set the ID to the next unique number
    def self.new(type = nil, to = nil, id = nil)
      node = super :iq
      node.type = type || :get
      node.to = to
      node.id = id || self.next_id
      node
    end

    def get?
      self.type == :get
    end
    
    def set?
      self.type == :set
    end
    
    def result?
      self.type == :result
    end
    
    def error?
      self.type == :error
    end

    ##
    # Ensures type is :get, :set, :result or :error
    def type=(type) # :nodoc:
      raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}" if type && !VALID_TYPES.include?(type.to_sym)
      super
    end
  end

end #Stanza
end
