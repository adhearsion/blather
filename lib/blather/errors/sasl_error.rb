module Blather

class SASLError < BlatherError
  SASL_ERR_NS = 'urn:ietf:params:xml:ns:xmpp-sasl'

  class_inheritable_accessor :err_name
  @@registrations = {}

  register :sasl_error

  def self.import(node)
    self.new node
  end

  def initialize(node)
    super()
    @node = node
  end

  def name
    @node.find_first('err_ns:*', :err_ns => SASL_ERR_NS).element_name.gsub('-', '_').to_sym if @node
  end
end #SASLError

end #Blather
