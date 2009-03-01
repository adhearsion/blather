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

      @parser = XML::SaxPushParser.new self
    end

    def parse(string)
      LOG.debug "PARSING: (#{string})" if @@debug
      @parser.receive(string) #unless string.blank?
    end

    NON_ATTRS = [nil, 'stream'].freeze
    def on_start_element_ns(elem, attrs, prefix, uri, namespaces)
      LOG.debug "START ELEM: (#{{:elem => elem, :attrs => attrs, :prefix => prefix, :uri => uri, :ns => namespaces}.inspect})" if @@debug
      elem = "#{"#{prefix}:" if prefix}#{elem}"
      e = XMPPNode.new elem
      XML::Namespace.new(e, prefix, uri)
      attrs.each { |k,v| e.attributes[k] = v if k }

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
      LOG.debug "END ELEM: #{{:elem => elem, :prefix => prefix, :uri => uri}.inspect}" if @@debug

      if !@current && "#{prefix}:#{elem}" =~ STREAM_REGEX
        @receiver.receive XMPPNode.new('stream:end')

      elsif @current.parent?
        @current = @current.parent

      else
        c, @current = @current, nil
        XML::Document.new.root = c
        @receiver.receive c

      end
    end

    def on_error(msg)
      raise StreamError::ParseError, msg.to_s
    end
  end #Parser

end #Stream
end #Blather