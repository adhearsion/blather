module Blather
class Stanza

  class Disco < Iq::Query
    def node
      query[:node]
    end

    def node=(node)
      query[:node] = node
    end
  end

end #Stanza
end #Blather
