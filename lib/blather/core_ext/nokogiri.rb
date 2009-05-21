module Nokogiri # :nodoc:
module XML

  class Node
    alias_method :element_name, :name
    alias_method :element_name=, :name=

    alias_method :attr_set, :[]=
    def []=(name, value)
      name = name.to_s
      value.nil? ? remove_attribute(name) : attr_set(name, value)
    end

    alias_method :attr_get, :[]
    def [](name)
      attr_get name.to_s
    end
  end

end #XML
end #Blather
