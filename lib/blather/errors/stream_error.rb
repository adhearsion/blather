module Blather

##
# Stream Errors
# RFC3920 Section 9.3 (http://xmpp.org/rfcs/rfc3920.html#streams-error-rules)
class StreamError < BlatherError
  register :stream_error

  attr_reader :text, :extras

  ##
  # Factory method for instantiating the proper class
  # for the error
  def self.import(node)
    name = node.find_first('descendant::*[name()!="text"]', 'urn:ietf:params:xml:ns:xmpp-streams').element_name
    text = node.find_first '//err_ns:text', :err_ns => 'urn:ietf:params:xml:ns:xmpp-streams'
    text = text.content if text

    extras = node.find("descendant::*[name()!='text' and name()!='#{name}']").map { |n| n }

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

    err = XMPPNode.new(@name)
    err.namespace = 'urn:ietf:params:xml:ns:xmpp-streams'
    node << err

    if self.text
      text = XMPPNode.new('text')
      text.namespace = 'urn:ietf:params:xml:ns:xmpp-streams'
      text << self.text
      node << text
    end

    self.extras.each do |extra|
      extra_copy = extra.copy
      extra_copy.namespace = extra.namespace
      node << extra_copy
    end
    node
  end

  ##
  # Turns the object into XML fit to be sent over the stream
  def to_xml
    to_node.to_s
  end

  def inspect # :nodoc:
    "Stream Error (#{@name}): #{self.text}"
  end
  alias_method :to_s, :inspect # :nodoc:
end #StreamError

end #Blather
