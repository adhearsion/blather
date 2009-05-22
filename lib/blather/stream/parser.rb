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
      @namespaces = {}
      @namespace_definitions = []
      @parser = Nokogiri::XML::SAX::PushParser.new self
    end

    def receive_data(string)
      LOG.debug "PARSING: (#{string})" if @@debug
      @stream_error = string =~ /stream:error/
      @parser.write string
    end

    def start_document; end
    def end_document; end
    def warning(*args); end

    def start_element_ns(elem, attrs, prefix, uri, namespaces)
      LOG.debug "START ELEM: (#{[elem, attrs, prefix, uri, namespaces].inspect})" if @@debug

      args = [elem]
      args << @current.document if @current
      node = XMPPNode.new *args
      node.document.root = node unless @current

      attrs.each { |k,v| node[k] = v if k }

      if !@receiver.stopped?
        @current << node if @current
        @current = node
      end

      @namespace_definitions.push []
      namespaces.each do |pre, href|
        next if @namespace_definitions.flatten.include?(@namespaces[[pre, href]])
        ns = node.add_namespace(pre, href)
        @namespaces[[pre, href]] ||= ns
      end
      @namespaces[[prefix, uri]] ||= node.add_namespace(prefix, uri) unless !prefix || namespaces[prefix]
      node.namespace = @namespaces[[prefix, uri]]

      deliver(node) if elem == 'stream' && !@stream_error

=begin
      $stderr.puts "\n\n"
      $stderr.puts [elem, attrs, prefix, uri, namespaces].inspect
      $stderr.puts @namespaces.inspect
      $stderr.puts [@namespaces[[prefix, uri]].prefix, @namespaces[[prefix, uri]].href].inspect if @namespaces[[prefix, uri]]
      $stderr.puts node.inspect
      $stderr.puts node.document.to_s.gsub(/\n\s*/,'')
=end
    end

    def end_element_ns(elem, prefix, uri)
      LOG.debug "END ELEM: #{[elem, prefix, uri].inspect}" if @@debug

      if elem == 'stream'
        deliver XMPPNode.new('stream:end')
      elsif @current.parent != @current.document
        @namespace_definitions.pop
        @current = @current.parent
      else
        deliver @current
      end
    end

    def characters(chars = '')
      LOG.debug "CHARS: #{chars}" if @@debug
      @current << Nokogiri::XML::Text.new(chars, @current.document) if @current
    end

    def error(msg)
      raise ParseError.new(msg)
    end

  private
    def deliver(node)
      @current, @namespaces, @namespace_definitions = nil, {}, []
      @receiver.receive node
    end
  end #Parser

end #Stream
end #Blather
