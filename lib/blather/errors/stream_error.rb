module Blather

##
# Stream Errors
# RFC3920 Section 9.3 (http://xmpp.org/rfcs/rfc3920.html#streams-error-rules)
class StreamError < BlatherError
  STREAM_ERR_NS = 'urn:ietf:params:xml:ns:xmpp-streams'

  register :stream_error

  attr_reader :text, :extras

  ##
  # Factory method for instantiating the proper class
  # for the error
  def self.import(node)
    name = node.find_first('descendant::*[name()!="text"]', STREAM_ERR_NS).element_name

    text = node.find_first 'descendant::*[name()="text"]', STREAM_ERR_NS
    text = text.content if text

    extras = node.find("descendant::*[namespace-uri()!='#{STREAM_ERR_NS}']").map { |n| n }

    self.new name, text, extras
  end

  ##
  # <tt>text</tt> is the (optional) error message.
  # <tt>extras</tt> should be an array of nodes to attach to the error
  # each extra should be in an application specific namespace
  # see RFC3920 Section 4.7.2 (http://xmpp.org/rfcs/rfc3920.html#rfc.section.4.7.2)
  def initialize(name, text = nil, extras = [])
    @name = name
    @text = text
    @extras = extras
  end

  def name
    @name.gsub('-','_').to_sym
  end

  ##
  # Creates an XML node from the error
  def to_node
    node = XMPPNode.new('stream:error')

    node << (err = XMPPNode.new(@name, node.document))
    err.namespace = 'urn:ietf:params:xml:ns:xmpp-streams'

    if self.text
      node << (text = XMPPNode.new('text', node.document))
      text.namespace = 'urn:ietf:params:xml:ns:xmpp-streams'
      text.content = self.text
    end

    self.extras.each do |extra|
      node << (extra_copy = extra.dup)
      extra_copy.document = node.document
    end
    node
  end

  ##
  # Turns the object into XML fit to be sent over the stream
  def to_xml
    to_node.to_s
  end

  def inspect # :nodoc:
    "Stream Error (#{@name}): #{self.text}" + (self.extras.empty? ? '' : " [#{self.extras}]")
  end
  alias_method :to_s, :inspect # :nodoc:
end #StreamError

end #Blather
