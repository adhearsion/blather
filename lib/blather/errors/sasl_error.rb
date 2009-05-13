module Blather

class SASLError < BlatherError
  NAMESPACE = 'urn:ietf:params:xml:ns:xmpp-sasl'
  register :sasl_error

  def self.import(node)
    self.new node
  end

  def initialize(node)
    super()
    @node = node
  end

  def name
    @node.doc.find_first('/err_ns:failure/*[1]', :err_ns => NAMESPACE).element_name.gsub('-', '_').to_sym if @node
  end
end #SASLError

end #Blather
