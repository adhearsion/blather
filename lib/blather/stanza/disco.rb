module Blather
class Stanza

  class Disco < Iq::Query
    attribute_accessor :node, :to_sym => false
  end

end #Stanza
end #Blather
