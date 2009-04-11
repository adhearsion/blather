module LibXML # :nodoc:
  module XML # :nodoc:

    class Node
      alias_method :element_name, :name
      alias_method :element_name=, :name=
    end

    class Attributes
      # Helper method for removing attributes
      def remove(name)
        attribute = get_attribute(name.to_s)
        attribute.remove! if attribute
      end

      alias_method :old_hash_set, :[]= # :nodoc:
      def []=(name, val)
        val.nil? ? remove(name.to_s) : old_hash_set(name.to_s, val.to_s)
      end

      alias_method :old_hash_get, :[] # :nodoc:
      def [](name)
        old_hash_get name.to_s
      end
    end #Attributes

  end #XML
end #LibXML
