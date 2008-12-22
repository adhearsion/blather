module Blather # :nodoc:
module Stream # :nodoc:

  class Parser # :nodoc:
    STREAM_REGEX = %r{(/)?stream:stream}.freeze
    ERROR_REGEX = /^<(stream:[a-z]+)/.freeze

    @@debug = false
    def self.debug; @@debug; end
    def self.debug=(debug); @@debug = debug; end

    include XML::SaxParser::Callbacks

    def initialize(receiver)
      @receiver = receiver
      @current = nil

      @parser = XML::SaxParser.new
      @parser.io = StringIO.new
      @parser.callbacks = self
    end

    def parse(string)
      LOG.debug "PARSING: #{string}" if @@debug
      if string =~ STREAM_REGEX && $1
        @receiver.receive XMPPNode.new('stream:end')
      else
        string << "</stream:stream>" if string =~ STREAM_REGEX && !$1
        string.gsub!(ERROR_REGEX, "<\\1 xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'")

        @parser.string = string
        @parser.parse
      end
    end

    NON_ATTRS = [nil, 'stream'].freeze
    def on_start_element_ns(elem, attrs, prefix, uri, namespaces)
      LOG.debug "START ELEM: (#{{:elem => elem, :attrs => attrs, :prefix => prefix, :ns => namespaces}.inspect})" if @@debug
      elem = "#{"#{prefix}:" if prefix}#{elem}"
      e = XMPPNode.new elem
      attrs.each { |n,v| n = "xmlns#{":#{n}" if n}" if NON_ATTRS.include?(n); e.attributes[n] = v }

      if elem == 'stream:stream'
        @receiver.receive e

      elsif !@receiver.stopped?
        @current << e if @current
        @current = e

      end
    end

    def on_characters(chars = '')
      LOG.debug "CHARS: #{chars}" if @@debug
      @current << XML::Node.new_text(chars) if @current
    end

    def on_end_element_ns(elem, prefix, uri)
      LOG.debug "END ELEM: #{{:elem => elem, :prefix => prefix, :uri => uri, :current => @current}.inspect}" if @@debug

      elem = "#{"#{prefix}:" if prefix}#{elem}"
      return if elem =~ STREAM_REGEX

      if @current.parent?
        @current = @current.parent

      else
        c, @current = @current, nil
        @receiver.receive c

      end

      def on_error(msg)
        raise Blather::ParseError, msg.to_s
      end
    end
  end #Parser

end #Stream
end #Blather