module Blather

# Stream Errors
# [RFC3920 Section 9.3](http://xmpp.org/rfcs/rfc3920.html#streams-error-rules)
#
# @handler :stream_error
class StreamError < BlatherError
  # @private
  STREAM_ERR_NS = 'urn:ietf:params:xml:ns:xmpp-streams'

  register :stream_error

  attr_reader :text, :extras

  # Factory method for instantiating the proper class for the error
  #
  # @param [Blather::XMPPNode] node the importable node
  def self.import(node)
    name = node.find_first('descendant::*[name()!="text"]', STREAM_ERR_NS).element_name

    text = node.find_first 'descendant::*[name()="text"]', STREAM_ERR_NS
    text = text.content if text

    extras = node.find("descendant::*[namespace-uri()!='#{STREAM_ERR_NS}']").map { |n| n }

    self.new name, text, extras
  end

  # Create a new Stream Error
  # [RFC3920 Section 4.7.2](http://xmpp.org/rfcs/rfc3920.html#rfc.section.4.7.2)
  #
  # @param [String] name the error name
  # @param [String, nil] text optional error text
  # @param [Array<Blather::XMPPNode>] extras an array of extras to attach to the
  # error
  def initialize(name, text = nil, extras = [])
    @name = name
    @text = text
    @extras = extras
  end

  # The error name
  #
  # @return [Symbol]
  def name
    @name.gsub('-','_').to_sym
  end

  # Creates an XML node from the error
  #
  # @return [Blather::XMPPNode]
  def to_node
    node = XMPPNode.new('stream:error')

    node << (err = XMPPNode.new(@name, node.document))
    err.namespace = 'urn:ietf:params:xml:ns:xmpp-streams'

    if self.text
      node << (text = XMPPNode.new('text', node.document))
      text.namespace = 'urn:ietf:params:xml:ns:xmpp-streams'
      text.content = self.text
    end

    self.extras.each { |extra| node << extra.dup }
    node
  end

  # Convert the object to a proper node then convert it to a string
  #
  # @return [String]
  def to_xml
    to_node.to_s
  end

  # @private
  def inspect
    "Stream Error (#{@name}): #{self.text}" + (self.extras.empty? ? '' : " [#{self.extras}]")
  end
  # @private
  alias_method :to_s, :inspect
end  # StreamError

end  # Blather
