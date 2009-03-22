module Blather
class Stanza
class Iq

  class Disco < Query
    attribute_accessor :node, :to_sym => false
  end

end #Iq
end #Stanza
end #Blather
