module Blather # :nodoc:
class Stream # :nodoc:

  class Parser # :nodoc:
    STREAM_REGEX = %r{(/)?stream:stream}.freeze
    ERROR_REGEX = /^<(stream:[a-z]+)/.freeze

    @@debug = !false
    def self.debug; @@debug; end
    def self.debug=(debug); @@debug = debug; end

    def initialize(receiver)
      @receiver = receiver
      @current = nil
      @parser = XML::SaxPushParser.new self
    end

    def receive_data(string)
      LOG.debug "PARSING: (#{string})" if @@debug
      @stream_error = string =~ /stream:error/
      @parser.receive string
    end

    def on_start_element_ns(elem, attrs, prefix, uri, namespaces)
      LOG.debug "START ELEM: (#{{:elem => elem, :attrs => attrs, :prefix => prefix, :uri => uri, :ns => namespaces}.inspect})" if @@debug

      e = XMPPNode.new elem
      attrs.each { |k,v| e.attributes[k] = v if k }

      if @current && (ns = @current.namespaces.find_by_href(uri))
        e.namespace = ns
      else
        e.namespace = {prefix => uri}
      end

      if elem == 'stream' && !@stream_error
        XML::Document.new.root = e
        @receiver.receive e

      elsif !@receiver.stopped?
        @current << e  if @current
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

    def on_error(err)
      err_klass = case err.level
      when XML::Error::WARNING
        ParseWarning
      when XML::Error::ERROR, XML::Error::FATAL
        ParseError
      end
      raise err_klass.new(err)
    end
  end #Parser

end #Stream
end #Blather