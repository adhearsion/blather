module Blather
class Stanza

  ##
  # Base Error stanza
  class Error < Stanza
    def self.new_from(stanza, defined_condition, type, text = nil)
      err = XMPPNode.new(defined_condition)
      err['type'] = type
      err.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'

      if text
        text = XMPPNode.new(:text, text)
        text.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'
        err << text
      end

      elem = stanza.copy(true)
      elem.type = :error
      elem << err

      elem
    end

    def error?
      true
    end
  end #ErrorStanza

end #Stanza
end