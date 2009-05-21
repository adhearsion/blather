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

    alias_method :nokogiri_xpath, :xpath
    def xpath(*paths)
      paths[0] = paths[0].to_s
      if paths.size > 1 && (namespaces = paths.pop).is_a?(Hash)
        paths << namespaces.inject({}) { |h,v| h[v[0].to_s] = v[1]; h }
      end
      nokogiri_xpath *paths
    end
    alias_method :find, :xpath

    def find_first(*paths)
      xpath(*paths).first
    end
  end

end #XML
end #Blather
