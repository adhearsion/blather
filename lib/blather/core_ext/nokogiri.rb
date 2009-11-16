module Nokogiri
module XML

  class Node
    # Alias #name to #element_name so we can use #name in an XMPP Stanza context
    alias_method :element_name, :name
    alias_method :element_name=, :name=

    alias_method :attr_set, :[]= # :nodoc:
    # Override Nokogiri's attribute setter to add the ability to kill an attribute
    # by setting it to nil and to be able to lookup an attribute by symbol
    #
    # @param [#to_s] name the name of the attribute
    # @param [#to_s, nil] value the new value or nil to remove it
    def []=(name, value)
      name = name.to_s
      value.nil? ? remove_attribute(name) : attr_set(name, value.to_s)
    end

    alias_method :nokogiri_xpath, :xpath
    # Override Nokogiri's #xpath method to add the ability to use symbols for lookup
    # and namespace designation
    def xpath(*paths)
      paths[0] = paths[0].to_s
      if paths.size > 1 && (namespaces = paths.pop).is_a?(Hash)
        paths << namespaces.inject({}) { |h,v| h[v[0].to_s] = v[1]; h }
      end
      nokogiri_xpath *paths
    end
    alias_method :find, :xpath

    # Return the first element at a specified xpath
    # @see #xpath
    def find_first(*paths)
      xpath(*paths).first
    end
  end

end #XML
end #Blather
