module Blather
class Stanza

  class PubSubErrors < PubSub
    def node
      read_attr :node
    end

    def node=(node)
      write_attr :node, node
    end
  end

end #Stanza
end #Blather
