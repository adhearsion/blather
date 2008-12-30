module Blather
class Stanza

  ##
  # Base Error stanza
  class Error < Stanza
    VALID_TYPES = [:cancel, :continue, :modify, :auth, :wait].freeze

    attr_accessor :error_type

    def self.new_from(stanza, defined_condition, type, text = nil)
      raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}" unless VALID_TYPES.include?(type.to_sym)

      err = XMPPNode.new defined_condition
      err.attributes[:type] = type
      err.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'

      if text
        text = XMPPNode.new(:text, text)
        text.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'
        err << text
      end

      elem = new(stanza.element_name).inherit stanza
      elem.type = :error
      elem.error_type = type
      elem << err

      elem
    end
  end #ErrorStanza

end #Stanza
end