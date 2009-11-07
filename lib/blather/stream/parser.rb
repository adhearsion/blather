require 'nokogiri'

module Blather # :nodoc:
class Stream # :nodoc:

  class Parser # :nodoc:
    NS_TO_IGNORE = %w[jabber:client jabber:component:accept]

    @@debug = false
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
      Blather.logger.debug "PARSING: (#{string})" if @@debug
      @parser << string
      self
    end
    alias_method :<<, :receive_data

    def start_document; end
    def end_document; end
    def start_element(*args); end
    def end_element(*args); end
    def warning(*args); end
    def xmldecl(*args); end

    def start_element_namespace(elem, attrs, prefix, uri, namespaces)
      Blather.logger.debug "START ELEM: (#{{:elem => elem, :attrs => attrs, :prefix => prefix, :uri => uri, :ns => namespaces}.inspect})" if @@debug

      args = [elem]
      args << @current.document if @current
      node = XMPPNode.new *args
      node.document.root = node unless @current

      attrs.each do |attr|
        node[attr.localname] = attr.value
      end

      if !@receiver.stopped?
        @current << node if @current
        @current = node
      end


      ns_keys = namespaces.map { |pre, href| pre }
      namespaces.delete_if { |pre, href| NS_TO_IGNORE.include? href }
      @namespace_definitions.push []
      namespaces.each do |pre, href|
        next if @namespace_definitions.flatten.include?(@namespaces[[pre, href]])
        ns = node.add_namespace(pre, href)
        @namespaces[[pre, href]] ||= ns
      end
      @namespaces[[prefix, uri]] ||= node.add_namespace(prefix, uri) if prefix && !ns_keys.include?(prefix)
      node.namespace = @namespaces[[prefix, uri]]

      deliver(node) if elem == 'stream'

=begin
      $stderr.puts "\n\n"
      $stderr.puts [elem, attrs, prefix, uri, namespaces].inspect
      $stderr.puts @namespaces.inspect
      $stderr.puts [@namespaces[[prefix, uri]].prefix, @namespaces[[prefix, uri]].href].inspect if @namespaces[[prefix, uri]]
      $stderr.puts node.inspect
      $stderr.puts node.document.to_s.gsub(/\n\s*/,'')
=end
    end

    def end_element_namespace(elem, prefix, uri)
      Blather.logger.debug "END ELEM: #{{:elem => elem, :prefix => prefix, :uri => uri}.inspect}" if @@debug

      if elem == 'stream'
        node = XMPPNode.new('end')
        node.namespace = {prefix => uri}
        deliver node
      elsif @current.parent != @current.document
        @namespace_definitions.pop
        @current = @current.parent
      else
        deliver @current
      end
    end

    def characters(chars = '')
      Blather.logger.debug "CHARS: #{chars}" if @@debug
      @current << Nokogiri::XML::Text.new(chars, @current.document) if @current
    end

    def warning(msg)
      Blather.logger.debug "PARSE WARNING: #{msg}" if @@debug
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
