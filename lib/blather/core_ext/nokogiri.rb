require 'nokogiri'

# @private
module Nokogiri
  module XML
    class Node
      # Alias #name to #element_name so we can use #name in an XMPP Stanza context
      alias_method :element_name, :name
      alias_method :element_name=, :name=

      alias_method :attr_set, :[]=
      # Override Nokogiri's attribute setter to add the ability to kill an attribute
      # by setting it to nil and to be able to lookup an attribute by symbol
      #
      # @param [#to_s] name the name of the attribute
      # @param [#to_s, nil] value the new value or nil to remove it
      def []=(name, value)
        if value.nil?
          remove_attribute name.to_s
        else
          attr_set name, value
        end
      end

      alias_method :nokogiri_xpath, :xpath
      # Override Nokogiri's #xpath method to add the ability to use symbols for lookup
      def xpath(*paths)
        paths[0] = paths[0].to_s
        nokogiri_xpath *paths
      end
    end
  end
end
