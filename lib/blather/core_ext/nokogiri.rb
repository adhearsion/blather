require 'nokogiri'

# @private
module Nokogiri
  module XML
    class Node
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
    end
  end
end
