module Blather
class Stanza

  # # Iq Stanza
  #
  # [RFC 3920 Section 9.2.3 - IQ Semantics](http://xmpp.org/rfcs/rfc3920.html#rfc.section.9.2.3)
  #
  # Info/Query, or IQ, is a request-response mechanism, similar in some ways
  # to HTTP. The semantics of IQ enable an entity to make a request of, and
  # receive a response from, another entity. The data content of the request
  # and response is defined by the namespace declaration of a direct child
  # element of the IQ element, and the interaction is tracked by the
  # requesting entity through use of the 'id' attribute. Thus, IQ interactions
  # follow a common pattern of structured data exchange such as get/result or
  # set/result (although an error may be returned in reply to a request if
  # appropriate).
  #
  # ## "ID" Attribute
  #
  # Iq Stanzas require the ID attribute be set. Blather will handle this
  # automatically when a new Iq is created.
  #
  # ## "Type" Attribute
  #
  # * `:get` -- The stanza is a request for information or requirements.
  #
  # * `:set` -- The stanza provides required data, sets new values, or
  #   replaces existing values.
  #
  # * `:result` -- The stanza is a response to a successful get or set request.
  #
  # * `:error` -- An error has occurred regarding processing or delivery of a
  #   previously-sent get or set (see Stanza Errors).
  #
  # Blather provides a helper for each possible type:
  #
  #     Iq#get?
  #     Iq#set?
  #     Iq#result?
  #     Iq#error?
  #
  # Blather treats the `type` attribute like a normal ruby object attribute
  # providing a getter and setter. The default `type` is `get`.
  #
  #     iq = Iq.new
  #     iq.type               # => :get
  #     iq.get?               # => true
  #     iq.type = :set
  #     iq.set?               # => true
  #     iq.get?               # => false
  #
  #     iq.type = :invalid    # => RuntimeError
  #
  # @handler :iq
  class Iq < Stanza
    VALID_TYPES = [:get, :set, :result, :error].freeze

    register :iq

    # @private
    def self.import(node)
      klass = nil
      node.children.detect do |e|
        ns = e.namespace ? e.namespace.href : nil
        klass = class_from_registration(e.element_name, ns)
      end

      if klass && klass != self
        klass.import(node)
      else
        new(node[:type]).inherit(node)
      end
    end

    # Create a new Iq
    #
    # @param [Symbol, nil] type the type of stanza (:get, :set, :result, :error)
    # @param [Blather::JID, String, nil] jid the JID of the inteded recipient
    # @param [#to_s] id the stanza's ID. Leaving this nil will set the ID to
    #                the next unique number
    def self.new(type = nil, to = nil, id = nil)
      node = super :iq
      node.type = type || :get
      node.to = to
      node.id = id || self.next_id
      node
    end

    # Check if the IQ is of type :get
    #
    # @return [true, false]
    def get?
      self.type == :get
    end

    # Check if the IQ is of type :set
    #
    # @return [true, false]
    def set?
      self.type == :set
    end

    # Check if the IQ is of type :result
    #
    # @return [true, false]
    def result?
      self.type == :result
    end

    # Check if the IQ is of type :error
    #
    # @return [true, false]
    def error?
      self.type == :error
    end

    # Ensures type is :get, :set, :result or :error
    #
    # @param [#to_sym] type the Iq type. Must be one of VALID_TYPES
    def type=(type)
      if type && !VALID_TYPES.include?(type.to_sym)
        raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}"
      end
      super
    end

    # Overrides the parent method to ensure the reply is of type :result
    #
    # @return [self]
    def reply!
      super
      self.type = :result
      self.children.remove
      self
    end
  end

end
end
