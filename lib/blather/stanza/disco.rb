module Blather
class Stanza

  # # Disco Base class
  #
  # Use Blather::Stanza::DiscoInfo or Blather::Stanza::DiscoItems
  class Disco < Iq::Query

    # Get the name of the node
    #
    # @return [String] the node name
    def node
      query[:node]
    end

    # Set the name of the node
    #
    # @param [#to_s] node the new node name
    def node=(node)
      query[:node] = node
    end

    # Compare two Disco objects by name, type and category
    # @param [Disco] o the Identity object to compare against
    # @return [true, false]
    def eql?(o, *fields)
      super o, *(fields + [:node])
    end
  end

end # Stanza
end # Blather
