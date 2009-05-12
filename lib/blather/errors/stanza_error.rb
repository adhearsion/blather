module Blather

##
# Stanza errors
# RFC3920 Section 9.3 (http://xmpp.org/rfcs/rfc3920.html#stanzas-error)
class StanzaError < BlatherError
  VALID_TYPES = [:cancel, :continue, :modify, :auth, :wait]

  register :stanza_error

  attr_reader :original, :name, :type, :text, :extras

  ##
  # Factory method for instantiating the proper class
  # for the error
  def self.import(node)
    original = node.copy
    original.remove_child 'error'

    error_node = node.find_first '//*[local-name()="error"]'

    name = error_node.find_first('child::*[name()!="text"]', 'urn:ietf:params:xml:ns:xmpp-stanzas').element_name
    type = error_node['type']
    text = node.find_first '//err_ns:text', :err_ns => 'urn:ietf:params:xml:ns:xmpp-stanzas'
    text = text.content if text

    extras = error_node.find("descendant::*[name()!='text' and name()!='#{name}']").map { |n| n }

    self.new original, name, type, text, extras
  end

  ##
  # <tt>original</tt> An original node must be provided for stanza errors. You can't declare
  # a stanza error on without a stanza.
  # <tt>type</tt> is the error type specified in RFC3920 (http://xmpp.org/rfcs/rfc3920.html#rfc.section.9.3.2)
  # <tt>text</tt> is an option error description
  # <tt>extras</tt> an array of application specific nodes to add to the error. These should be properly namespaced.
  def initialize(original, name, type, text = nil, extras = [])
    @original = original
    @name = name
    self.type = type
    @text = text
    @extras = extras
  end

  ##
  # Set the error type (see RFC3920 Section 9.3.2 (http://xmpp.org/rfcs/rfc3920.html#rfc.section.9.3.2))
  def type=(type)
    type = type.to_sym
    raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}" if !VALID_TYPES.include?(type)
    @type = type
  end

  def name
    @name.gsub('-','_').to_sym
  end

  ##
  # Creates an XML node from the error
  def to_node
    node = self.original.reply

    error_node = XMPPNode.new 'error'
    err = XMPPNode.new(@name)
    err.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'
    error_node << err

    if self.text
      text = XMPPNode.new('text')
      text.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'
      text << self.text
      error_node << text
    end

    self.extras.each do |extra|
      extra_copy = extra.copy
      extra_copy.namespace = extra.namespace
      error_node << extra_copy
    end

    node << error_node
    node.type = 'error'
    node
  end

  ##
  # Turns the object into XML fit to be sent over the stream
  def to_xml
    to_node.to_s
  end

  def inspect # :nodoc:
    "Stanza Error (#{@name}): #{self.text}"
  end
  alias_method :to_s, :inspect # :nodoc:
end #StanzaError

end #Blather