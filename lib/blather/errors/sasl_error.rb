module Blather

# General SASL Errors
# Check #name for the error name
#
# @handler :sasl_error
class SASLError < BlatherError
  SASL_ERR_NS = 'urn:ietf:params:xml:ns:xmpp-sasl'

  class_inheritable_accessor :err_name
  @@registrations = {}

  register :sasl_error

  # Import the stanza
  #
  # @param [Blather::XMPPNode] node the error node
  # @return [Blather::SASLError]
  def self.import(node)
    self.new node
  end

  # Create a new SASLError
  #
  # @param [Blather::XMPPNode] node the error node
  def initialize(node)
    super()
    @node = node
  end

  # The actual error name
  #
  # @return [Symbol] a symbol representing the error name
  def name
    @node.find_first('err_ns:*', :err_ns => SASL_ERR_NS).element_name.gsub('-', '_').to_sym if @node
  end
end #SASLError

end #Blather
