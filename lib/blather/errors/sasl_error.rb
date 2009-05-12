module Blather

class SASLError < BlatherError
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
    @node.children.first.element_name.gsub('-', '_').to_sym if @node
  end
end #SASLError

end #Blather
