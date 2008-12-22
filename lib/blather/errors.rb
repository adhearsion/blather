module Blather
  # Main error class
  class BlatherError < StandardError; end

    #Parse Errors
    class ParseError < BlatherError; end

    # Stream errors
    class StreamError < BlatherError
      attr_accessor :type, :text

      def initialize(node)
        @type = node.detect { |n| n.name != 'text' && n['xmlns'] == 'urn:ietf:params:xml:ns:xmpp-streams' }
        @text = node.detect { |n| n.name == 'text' }

        @extra = node.detect { |n| n['xmlns'] != 'urn:ietf:params:xml:ns:xmpp-streams' }
      end

      def to_s
        "Stream Error (#{type.name}) #{"[#{@extra.name}]" if @extra}: #{text.content if text}"
      end
    end

    # Stanza errors
    class StanzaError < BlatherError; end
      class ArgumentError < StanzaError; end
end