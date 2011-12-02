module Blather
class Stream

  # @private
  class Parser < Nokogiri::XML::SAX::Document
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
      @parser.options = Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOENT
    end

    def receive_data(string)
      Blather.log "PARSING: (#{string})" if @@debug
      @parser << string
      self
    end
    alias_method :<<, :receive_data

    def start_element_namespace(elem, attrs, prefix, uri, namespaces)
      Blather.log "START ELEM: (#{{:elem => elem, :attrs => attrs, :prefix => prefix, :uri => uri, :ns => namespaces}.inspect})" if @@debug

      args = [elem]
      args << @current.document if @current
      node = XMPPNode.new *args
      node.document.root = node unless @current

      attrs.each do |attr|
        node[attr.localname] = attr.value
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

      if !@receiver.stopped?
        @current << node if @current
        @current = node
      end

      deliver(node) if elem == 'stream'

      # $stderr.puts "\n\n"
      # $stderr.puts [elem, attrs, prefix, uri, namespaces].inspect
      # $stderr.puts @namespaces.inspect
      # $stderr.puts [@namespaces[[prefix, uri]].prefix, @namespaces[[prefix, uri]].href].inspect if @namespaces[[prefix, uri]]
      # $stderr.puts node.inspect
      # $stderr.puts node.document.to_s.gsub(/\n\s*/,'')
    end

    def end_element_namespace(elem, prefix, uri)
      Blather.log "END ELEM: #{{:elem => elem, :prefix => prefix, :uri => uri}.inspect}" if @@debug

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
      Blather.log "CHARS: #{chars}" if @@debug
      @current << Nokogiri::XML::Text.new(chars, @current.document) if @current
    end

    def warning(msg)
      Blather.log "PARSE WARNING: #{msg}" if @@debug
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
