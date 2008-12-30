module Blather
  # Main error class
  class BlatherError < StandardError
    class_inheritable_array :handler_heirarchy
    self.handler_heirarchy ||= []
    self.handler_heirarchy << :error
  end

  #Parse Errors
  class ParseError < BlatherError
    self.handler_heirarchy ||= []
    self.handler_heirarchy.unshift :parse_error
  end

  # Stream errors
  class StreamError < BlatherError
    self.handler_heirarchy ||= []
    self.handler_heirarchy.unshift :stream_error

    attr_accessor :type, :text

    def initialize(node)
      @type = node.find_first('descendant::*[name()!="text"]', 'urn:ietf:params:xml:ns:xmpp-streams').element_name
      @text = node.find_first 'descendant::text', 'urn:ietf:params:xml:ns:xmpp-streams'
      @text = @text.content if @text

      @extra = node.find('descendant::*[@xmlns!="urn:ietf:params:xml:ns:xmpp-streams"]').map { |n| n.element_name }
    end

    def to_s
      "Stream Error (#{self.type}): #{self.text}"
    end
  end

  # Stanza errors
  class StanzaError < BlatherError
    handler_heirarchy ||= []
    handler_heirarchy.unshift :stanza_error
  end

  class ArgumentError < StanzaError
    handler_heirarchy ||= []
    handler_heirarchy.unshift :argument_error
  end
end