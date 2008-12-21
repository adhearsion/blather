module LibXML # :nodoc:
  module XML # :nodoc:

    class Node
      alias_method :element_name, :name
    end

    class Attributes
      # Helper method for removing attributes
      def remove(name)
        name = name.to_s
        self.each { |a| a.remove! or break if a.name == name }
      end
    end #Attributes

  end #XML
end #LibXML
