module Blather

# Stanza errors
# RFC3920 Section 9.3 (http://xmpp.org/rfcs/rfc3920.html#stanzas-error)
#
# @handler :stanza_error
class StanzaError < BlatherError
  # @private
  STANZA_ERR_NS = 'urn:ietf:params:xml:ns:xmpp-stanzas'
  # @private
  VALID_TYPES = [:cancel, :continue, :modify, :auth, :wait].freeze

  register :stanza_error

  attr_reader :original, :name, :type, :text, :extras

  # Factory method for instantiating the proper class for the error
  #
  # @param [Blather::XMPPNode] node the error node to import
  # @return [Blather::StanzaError]
  def self.import(node)
    original = node.copy
    original.remove_child 'error'

    error_node = node.at_xpath '//*[local-name()="error"]'

    name = error_node.at_xpath('child::*[name()!="text"]').element_name
    type = error_node['type']
    text = node.at_xpath 'descendant::*[name()="text"]'
    text = text.content if text

    extras = error_node.xpath("descendant::*[name()!='text' and name()!='#{name}']").map { |n| n }

    self.new original, name, type, text, extras
  end

  # Create a new StanzaError
  #
  # @param [Blather::XMPPNode] original the original stanza
  # @param [String] name the error name
  # @param [#to_s] type the error type as specified in
  # [RFC3920](http://xmpp.org/rfcs/rfc3920.html#rfc.section.9.3.2)
  # @param [String, nil] text additional text for the error
  # @param [Array<Blather::XMPPNode>] extras an array of extra nodes to add
  def initialize(original, name, type, text = nil, extras = [])
    @original = original
    @name = name
    self.type = type
    @text = text
    @extras = extras
  end

  # Set the error type
  #
  # @param [#to_sym] type the new error type. Must be on of
  # Blather::StanzaError::VALID_TYPES
  # @see [RFC3920 Section 9.3.2](http://xmpp.org/rfcs/rfc3920.html#rfc.section.9.3.2)
  def type=(type)
    type = type.to_sym
    if !VALID_TYPES.include?(type)
      raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}"
    end
    @type = type
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
    node = self.original.reply
    node.type = 'error'
    node << (error_node = XMPPNode.new('error'))

    error_node << (err = XMPPNode.new(@name, error_node.document))
    error_node['type'] = self.type
    err.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'

    if self.text
      error_node << (text = XMPPNode.new('text', error_node.document))
      text.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'
      text.content = self.text
    end

    self.extras.each { |extra| error_node << extra.dup }
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
    "Stanza Error (#{@name}): #{self.text} [#{self.extras}]"
  end
  # @private
  alias_method :to_s, :inspect
end  # StanzaError

end  # Blather
