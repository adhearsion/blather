module Blather
class Stanza

  class PubSubOwner < PubSub
    attribute_accessor :node, :to_sym => false
  end

end #Stanza
end #Blather
