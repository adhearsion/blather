require 'nokogiri'

module Blather # :nodoc:
class Stream # :nodoc:

  class Parser # :nodoc:

    @@debug = !false
    def self.debug; @@debug; end
    def self.debug=(debug); @@debug = debug; end

    def initialize(receiver)
      @receiver = receiver
      @current = nil
      @parser = Nokogiri::XML::SAX::PushParser.new self
    end

    def receive_data(string)
      LOG.debug "PARSING: (#{string})" if @@debug
      @stream_error = string =~ /stream:error/
      @parser.write string
    rescue RuntimeError
      if $!.message == "Couldn't parse chunk"
        raise ParseError, $!.message
      else
        raise
      end
    end

    def start_document
    end

    def start_element(elem, attributes_array)
      e = XMPPNode.new(elem)
      key = value = nil
      attributes_array.each do |item|
        if key
          case key
          when "xmlns"
            e.namespaces.namespace = XML::Namespace.new(e, nil, item)
          when /^xmlns:(.*)$/
            e.namespaces.namespace = XML::Namespace.new(e, $1, item)
          else
            e[key] = item
          end
          key = nil
        else
          key = item
        end
      end
      LOG.debug "START ELEM: (#{elem.inspect}, #{attributes_array.inspect})" if @@debug

      if elem == 'stream:stream' && !@stream_error
        XML::Document.new.root = e
        @receiver.receive e

      elsif !@receiver.stopped?
        @current << e  if @current
        @current = e
      end
    end

    def characters(chars = '')
      LOG.debug "CHARS: #{chars}" if @@debug
      @current << XML::Node.new_text(chars) if @current
    end

    def end_element(elem)
      LOG.debug "END ELEM: #{elem.inspect}" if @@debug

      if !@current && elem == "stream:stream"
        @receiver.receive XMPPNode.new('stream:end')

      elsif @current.parent?
        @current = @current.parent

      else
        c, @current = @current, nil
        XML::Document.new.root = c
        @receiver.receive c

      end
    end

    def end_document
    end
  end #Parser

end #Stream
end #Blather
